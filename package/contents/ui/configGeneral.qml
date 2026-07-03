// SPDX-FileCopyrightText: 2026 Yakir Rettig
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: page

    // Settings bound by Plasma's config dialog via the cfg_<key> convention.
    // Declared so they're picked up by the binding machinery.
    property string cfg_lightTheme
    property string cfg_darkTheme
    property int    cfg_clickAction
    property int    cfg_iconStyle

    Kirigami.FormLayout {
        anchors.fill: parent

        ComboBox {
            id: lightCombo
            Kirigami.FormData.label: i18n("Light theme:")
            model: themeModel
            textRole: "name"
            valueRole: "id"
            Layout.fillWidth: true
            currentIndex: themeModel.indexOf(cfg_lightTheme)
            onActivated: cfg_lightTheme = currentValue
        }

        ComboBox {
            id: darkCombo
            Kirigami.FormData.label: i18n("Dark theme:")
            model: themeModel
            textRole: "name"
            valueRole: "id"
            Layout.fillWidth: true
            currentIndex: themeModel.indexOf(cfg_darkTheme)
            onActivated: cfg_darkTheme = currentValue
        }

        Item { Kirigami.FormData.isSection: true }

        ComboBox {
            Kirigami.FormData.label: i18n("Click action:")
            model: [
                i18n("Toggle between light and dark"),
                i18n("Show menu"),
                i18n("Cycle (light → dark → …)")
            ]
            currentIndex: cfg_clickAction
            onActivated: cfg_clickAction = currentIndex
        }

        ComboBox {
            Kirigami.FormData.label: i18n("Icon style:")
            model: [
                i18n("Follow current scheme"),
                i18n("Sun / moon"),
                i18n("Yin-yang")
            ]
            currentIndex: cfg_iconStyle
            onActivated: cfg_iconStyle = currentIndex
        }
    }

    // ── Theme enumeration ─────────────────────────────────────────
    //
    // Pure-QML option (a) per DESIGN.md: shell out to
    //   plasma-apply-lookandfeel --list
    // and parse the output. Each line looks like:
    //   * org.kde.breeze.desktop (current)
    //     org.kde.breezedark.desktop
    // Strip the leading marker, treat the id as both the value and a
    // human-readable display (we don't have a Name without KPackage —
    // good enough for v0.1; the id is reverse-DNS and recognisable).

    ListModel {
        id: themeModel

        function indexOf(id) {
            for (let i = 0; i < count; ++i) {
                if (get(i).id === id) return i
            }
            return -1
        }
    }

    P5Support.DataSource {
        id: themeLister
        engine: "executable"
        connectedSources: ["plasma-apply-lookandfeel --list"]
        onNewData: (sourceName, data) => {
            const out = (data["stdout"] || "").toString()
            themeModel.clear()
            for (const raw of out.split("\n")) {
                const line = raw.replace(/^[\s*]+/, "").trim()
                if (!line) continue
                const id = line.split(/\s+/)[0]
                if (!id) continue
                themeModel.append({ id: id, name: id })
            }
            // Re-sync ComboBox indices now that the model is populated
            lightCombo.currentIndex = themeModel.indexOf(cfg_lightTheme)
            darkCombo.currentIndex  = themeModel.indexOf(cfg_darkTheme)
            disconnectSource(sourceName)
        }
    }
}
