// SPDX-FileCopyrightText: 2026 Yakir Rettig
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import org.kde.notification

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Theme Toggle")
    toolTipSubText: Plasmoid.configuration.lastAppliedWasDark
        ? i18n("Currently dark — click to switch to light")
        : i18n("Currently light — click to switch to dark")

    // ── Theme application ──────────────────────────────────────────

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)

        function exec(cmd) {
            connectSource(cmd)
        }
    }

    Notification {
        id: switchNotification
        componentName: "plasma_workspace"
        eventId: "notification"
        title: i18n("Theme Toggle")
        iconName: "preferences-desktop-theme-global"
        urgency: Notification.LowUrgency
    }

    function applyTheme(themeId, isDark) {
        if (!themeId) return
        // Look-and-Feel ids are reverse-DNS (no spaces), but quote defensively.
        const safeId = themeId.replace(/'/g, "'\\''")
        executable.exec("plasma-apply-lookandfeel --apply '" + safeId + "'")
        Plasmoid.configuration.lastAppliedWasDark = isDark
        if (Plasmoid.configuration.notifyOnSwitch && Plasmoid.configuration.autoSwitchEnabled) {
            switchNotification.text = isDark
                ? i18n("Switched to dark theme")
                : i18n("Switched to light theme")
            switchNotification.sendEvent()
        }
    }

    function toggle() {
        if (Plasmoid.configuration.lastAppliedWasDark) {
            applyTheme(Plasmoid.configuration.lightTheme, false)
        } else {
            applyTheme(Plasmoid.configuration.darkTheme, true)
        }
    }

    // ── Schedule (auto-switch) ─────────────────────────────────────
    //
    // Tick every 30s while autoSwitch is enabled. On every tick, compute
    // which side of the schedule "now" falls on and re-apply if needed.
    // Re-checking the desired state (rather than just firing once at the
    // boundary) means we recover for free from suspend, missed ticks, and
    // mid-day toggles by the user.

    Timer {
        id: scheduleTicker
        interval: 30 * 1000
        running: Plasmoid.configuration.autoSwitchEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkSchedule()
    }

    function parseHHMM(s) {
        const m = /^(\d{1,2}):(\d{2})$/.exec(s || "")
        if (!m) return null
        const h = parseInt(m[1], 10)
        const min = parseInt(m[2], 10)
        if (h < 0 || h > 23 || min < 0 || min > 59) return null
        return h * 60 + min
    }

    function checkSchedule() {
        if (!Plasmoid.configuration.autoSwitchEnabled) return
        if (Plasmoid.configuration.autoSwitchMode !== 0 /* FixedTimes */) return  // sunrise/sunset stubbed

        const lightStart = parseHHMM(Plasmoid.configuration.lightTime)
        const darkStart  = parseHHMM(Plasmoid.configuration.darkTime)
        if (lightStart === null || darkStart === null) return

        const now = new Date()
        const nowMin = now.getHours() * 60 + now.getMinutes()

        // Determine which window "now" falls in. The two boundaries split
        // the day into a "light" arc and a "dark" arc; works whether
        // light < dark or dark < light (e.g. light=07:00 dark=19:00 vs.
        // a hypothetical light=19:00 dark=07:00).
        let shouldBeDark
        if (lightStart < darkStart) {
            shouldBeDark = (nowMin < lightStart) || (nowMin >= darkStart)
        } else {
            shouldBeDark = (nowMin >= darkStart) && (nowMin < lightStart)
        }

        if (shouldBeDark !== Plasmoid.configuration.lastAppliedWasDark) {
            if (shouldBeDark) {
                applyTheme(Plasmoid.configuration.darkTheme, true)
            } else {
                applyTheme(Plasmoid.configuration.lightTheme, false)
            }
        }
    }

    // ── Compact representation (panel button) ──────────────────────

    compactRepresentation: MouseArea {
        id: rootArea
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        readonly property string iconName: {
            switch (Plasmoid.configuration.iconStyle) {
            case 1: return Plasmoid.configuration.lastAppliedWasDark ? "weather-clear-night" : "weather-clear"
            case 2: return Qt.resolvedUrl("../icons/themetoggle.svg")
            case 0:
            default:
                return Plasmoid.configuration.lastAppliedWasDark
                    ? "preferences-desktop-color"
                    : "preferences-desktop-theme-global"
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: rootArea.iconName
            active: rootArea.containsMouse
        }

        onClicked: root.toggle()
    }
}
