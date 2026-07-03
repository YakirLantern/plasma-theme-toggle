// SPDX-FileCopyrightText: 2026 Yakir Rettig
// SPDX-License-Identifier: GPL-3.0-or-later
//
// v0.1 stub. The full Advanced tab will expose per-component overrides
// (Color Scheme / Plasma Style / Window Decoration / Icon Theme / Cursor
// Theme / Wallpaper / GTK theme), each as two ComboBoxes — one for the
// light state and one for the dark state, defaulting to "From Global
// Theme". Adding the dropdowns is straightforward once the General tab's
// theme-enumeration approach (P5Support.DataSource shelling out to a
// kpackagetool6 list) is generalised; that's deferred until v0.2.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property bool cfg_useAdvancedOverrides

    Kirigami.FormLayout {
        anchors.fill: parent

        CheckBox {
            Kirigami.FormData.label: i18n("Per-component overrides:")
            text: i18n("Override individual theme components instead of using a Global Theme")
            checked: cfg_useAdvancedOverrides
            onToggled: cfg_useAdvancedOverrides = checked
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            visible: true
            type: Kirigami.MessageType.Information
            text: i18n("Per-component overrides are not implemented yet. In v0.2 this tab will let you pick separate Color Scheme, Plasma Style, Window Decoration, Icon Theme, Cursor Theme, Wallpaper and GTK theme for the light and dark states.")
        }
    }
}
