// SPDX-FileCopyrightText: 2026 Yakir Rettig
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property bool   cfg_autoSwitchEnabled
    property int    cfg_autoSwitchMode
    property string cfg_lightTime
    property string cfg_darkTime
    property bool   cfg_notifyOnSwitch

    // Helper: pad single-digit numbers to two chars.
    function pad(n) { return n < 10 ? "0" + n : "" + n }

    // Helper: parse "HH:MM" into [hour, minute] with safe fallback.
    function parts(s) {
        const m = /^(\d{1,2}):(\d{2})$/.exec(s || "")
        if (!m) return [0, 0]
        return [parseInt(m[1], 10), parseInt(m[2], 10)]
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        CheckBox {
            id: enableBox
            Kirigami.FormData.label: i18n("Auto switch:")
            text: i18n("Switch theme automatically based on time of day")
            checked: cfg_autoSwitchEnabled
            onToggled: cfg_autoSwitchEnabled = checked
        }

        Item { Kirigami.FormData.isSection: true }

        ComboBox {
            id: modeCombo
            Kirigami.FormData.label: i18n("Mode:")
            enabled: cfg_autoSwitchEnabled
            model: [
                i18n("Fixed times"),
                i18n("Sunrise / sunset (coming soon)")
            ]
            currentIndex: cfg_autoSwitchMode
            onActivated: {
                // Sunrise/sunset is stubbed in v0.1 — refuse to commit it.
                if (currentIndex === 1) {
                    currentIndex = 0
                    return
                }
                cfg_autoSwitchMode = currentIndex
            }
        }

        // ── Light start time ─────────────────────────────────────
        RowLayout {
            Kirigami.FormData.label: i18n("Light theme starts at:")
            enabled: cfg_autoSwitchEnabled && cfg_autoSwitchMode === 0
            spacing: Kirigami.Units.smallSpacing

            SpinBox {
                id: lightHour
                from: 0; to: 23
                editable: true
                value: page.parts(cfg_lightTime)[0]
                onValueModified: cfg_lightTime = page.pad(value) + ":" + page.pad(lightMinute.value)
            }
            Label { text: ":" }
            SpinBox {
                id: lightMinute
                from: 0; to: 59
                editable: true
                value: page.parts(cfg_lightTime)[1]
                onValueModified: cfg_lightTime = page.pad(lightHour.value) + ":" + page.pad(value)
            }
            Item { Layout.fillWidth: true }
        }

        // ── Dark start time ──────────────────────────────────────
        RowLayout {
            Kirigami.FormData.label: i18n("Dark theme starts at:")
            enabled: cfg_autoSwitchEnabled && cfg_autoSwitchMode === 0
            spacing: Kirigami.Units.smallSpacing

            SpinBox {
                id: darkHour
                from: 0; to: 23
                editable: true
                value: page.parts(cfg_darkTime)[0]
                onValueModified: cfg_darkTime = page.pad(value) + ":" + page.pad(darkMinute.value)
            }
            Label { text: ":" }
            SpinBox {
                id: darkMinute
                from: 0; to: 59
                editable: true
                value: page.parts(cfg_darkTime)[1]
                onValueModified: cfg_darkTime = page.pad(darkHour.value) + ":" + page.pad(value)
            }
            Item { Layout.fillWidth: true }
        }

        Item { Kirigami.FormData.isSection: true }

        CheckBox {
            Kirigami.FormData.label: i18n("Notification:")
            text: i18n("Show a notification when the schedule fires")
            enabled: cfg_autoSwitchEnabled
            checked: cfg_notifyOnSwitch
            onToggled: cfg_notifyOnSwitch = checked
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            visible: cfg_autoSwitchEnabled
            type: Kirigami.MessageType.Information
            text: i18n("Schedule is checked every 30 seconds. The widget recovers from suspend automatically — if your laptop sleeps across a switch time, the correct theme is applied on the next tick after wake.")
        }
    }
}
