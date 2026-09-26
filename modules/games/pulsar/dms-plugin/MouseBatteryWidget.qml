import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property int level: -1
    property bool charging: false
    readonly property bool connected: level >= 0
    readonly property string icon: !connected ? "link_off" : charging ? "battery_charging_full" : "mouse"
    readonly property color tint: !connected ? Theme.widgetInactiveIconColor : level <= 20 && !charging ? Theme.error : Theme.widgetTextColor

    Process {
        id: proc
        command: ["@pulsarBattery@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                const level = parseInt(parts[0]);
                root.level = isNaN(level) ? -1 : level;
                root.charging = parts[1] === "1";
            }
        }
    }

    // The mouse sleeps after about a minute idle and the dongle does not announce wake-ups.
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: root.icon
                size: Theme.fontSizeLarge
                color: root.tint
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.connected
                text: root.level + "%"
                font.pixelSize: Theme.fontSizeMedium
                color: root.tint
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                name: root.icon
                size: Theme.fontSizeLarge
                color: root.tint
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.connected
                text: root.level
                font.pixelSize: Theme.fontSizeSmall
                color: root.tint
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
