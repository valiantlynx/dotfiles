import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 820
    height: 620
    visible: true
    color: backend.theme.background
    title: backend.title

    property color bg: backend.theme.background
    property color panel: backend.theme.backgroundPanel
    property color panelAlt: backend.theme.backgroundElement
    property color border: backend.theme.border
    property color textStrong: backend.theme.text
    property color textSoft: backend.theme.textMuted
    property color primary: backend.theme.primary
    property color secondary: backend.theme.secondary
    property color accent: backend.theme.accent

    Rectangle {
        anchors.fill: parent
        color: bg

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.22) }
            }
        }

        Rectangle {
            width: parent.width * 0.75
            height: width
            radius: width / 2
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -120
            anchors.verticalCenterOffset: -80
            color: primary
            opacity: 0.08
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 0.92; to: 1.05; duration: 6000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.05; to: 0.92; duration: 6000; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            width: parent.width * 0.68
            height: width
            radius: width / 2
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 130
            anchors.verticalCenterOffset: 110
            color: accent
            opacity: 0.06
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.04; to: 0.95; duration: 7000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.95; to: 1.04; duration: 7000; easing.type: Easing.InOutSine }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 18

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                radius: 22
                color: panel
                border.color: border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    ColumnLayout {
                        spacing: 4
                        Label {
                            text: backend.title
                            color: textStrong
                            font.pixelSize: 24
                            font.bold: true
                        }
                        Label {
                            text: backend.subtitle
                            color: textSoft
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Pulse"
                        onClicked: backend.next_message()
                    }
                    Button {
                        text: "Refresh Theme"
                        onClicked: backend.refresh_theme()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    radius: 30
                    color: panel
                    border.color: border
                }

                Item {
                    id: orbStage
                    anchors.centerIn: parent
                    width: 320
                    height: 320

                    property real t: 0
                    NumberAnimation on t {
                        from: 0
                        to: Math.PI * 2
                        duration: 16000
                        loops: Animation.Infinite
                        running: true
                    }

                    Rectangle {
                        width: 280
                        height: 280
                        radius: 140
                        anchors.centerIn: parent
                        x: (orbStage.width - width) / 2 + Math.cos(orbStage.t * 1.3) * 18
                        y: (orbStage.height - height) / 2 + Math.sin(orbStage.t * 1.1) * 12
                        color: primary
                        opacity: 0.10
                    }

                    Rectangle {
                        width: 220
                        height: 220
                        radius: 110
                        anchors.centerIn: parent
                        x: (orbStage.width - width) / 2 + Math.sin(orbStage.t * 1.7) * -20
                        y: (orbStage.height - height) / 2 + Math.cos(orbStage.t * 1.4) * 14
                        color: accent
                        opacity: 0.10
                    }

                    Repeater {
                        model: 18
                        Rectangle {
                            property real phase: index * 0.6
                            width: (index % 3) + 3
                            height: width
                            radius: width / 2
                            color: index % 2 === 0 ? primary : accent
                            opacity: 0.25
                            x: orbStage.width / 2 + Math.cos(orbStage.t * 2 + phase) * (55 + index * 4) - width / 2
                            y: orbStage.height / 2 + Math.sin(orbStage.t * 2 + phase) * (40 + index * 4) - height / 2
                        }
                    }

                    Rectangle {
                        id: outerGlow
                        width: 150
                        height: 150
                        radius: 75
                        anchors.centerIn: parent
                        color: primary
                        opacity: 0.22
                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.92; to: 1.08; duration: 2600; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.08; to: 0.92; duration: 2600; easing.type: Easing.InOutSine }
                        }
                    }

                    Rectangle {
                        width: 110
                        height: 110
                        radius: 55
                        anchors.centerIn: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: primary }
                            GradientStop { position: 1.0; color: accent }
                        }
                        SequentialAnimation on rotation {
                            loops: Animation.Infinite
                            NumberAnimation { from: -10; to: 10; duration: 5000; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 10; to: -10; duration: 5000; easing.type: Easing.InOutSine }
                        }
                    }

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        anchors.centerIn: parent
                        color: textStrong
                        opacity: 0.14
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 24
                    height: 112
                    radius: 24
                    color: panelAlt
                    border.color: border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 6

                        Label {
                            text: "Signal"
                            color: textSoft
                            font.pixelSize: 12
                        }
                        Label {
                            text: backend.line
                            color: textStrong
                            font.pixelSize: 18
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
