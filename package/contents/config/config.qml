// SPDX-FileCopyrightText: 2026 Yakir Rettig
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-theme-global"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Auto switch")
        icon: "view-calendar-time-spent"
        source: "configAutoSwitch.qml"
    }
    ConfigCategory {
        name: i18n("Advanced")
        icon: "configure"
        source: "configAdvanced.qml"
    }
}
