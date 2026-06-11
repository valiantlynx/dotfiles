import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 1240
    height: 800
    visible: true
    color: "#0c1017"
    title: "Hypr Monitors"

    property var monitorState: []
    property int selectedIndex: 0
    property string statusText: ""
    property bool statusOk: true

    property color bg: "#0c1017"
    property color panel: "#141a23"
    property color panelAlt: "#1a2230"
    property color border: "#41474d"
    property color borderActive: "#8b9198"
    property color textStrong: "#e0e3e8"
    property color textSoft: "#c1c7ce"
    property color accent: "#96cdf8"
    property color accentSoft: "#1c2024"
    property color success: "#b7c9d9"
    property color danger: "#ffb4ab"

    component ChromeButton: Button {
        id: control
        implicitHeight: 36
        implicitWidth: 88
        contentItem: Text {
            text: control.text
            color: textStrong
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
            font.bold: true
            opacity: control.enabled ? 1.0 : 0.45
        }
        background: Rectangle {
            color: control.down ? panelAlt : panel
            border.color: control.activeFocus ? borderActive : border
            border.width: 1
        }
    }

    component ChromeCombo: ComboBox {
        id: control
        implicitHeight: 36
        contentItem: Text {
            leftPadding: 10
            rightPadding: 28
            text: control.displayText
            color: textStrong
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.pixelSize: 12
        }
        background: Rectangle {
            color: panel
            border.color: control.activeFocus ? borderActive : border
            border.width: 1
        }
        indicator: Text {
            text: "v"
            color: textSoft
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            font.pixelSize: 10
        }
        popup: Popup {
            y: control.height
            width: control.width
            padding: 0
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.delegateModel
                currentIndex: control.highlightedIndex
            }
            background: Rectangle {
                color: panelAlt
                border.color: border
                border.width: 1
            }
        }
        delegate: ItemDelegate {
            width: control.width
            contentItem: Text {
                text: modelData
                color: textStrong
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 12
            }
            background: Rectangle {
                color: highlighted ? accentSoft : panelAlt
            }
        }
    }

    function cloneData(data) {
        return JSON.parse(JSON.stringify(data))
    }

    function loadState() {
        monitorState = cloneData(backend.monitors)
        applyTheme()
        statusText = ""
        for (let i = 0; i < monitorState.length; i++) {
            if (monitorState[i].focused) {
                selectedIndex = i
                return
            }
        }
        selectedIndex = 0
    }

    function selectedMonitor() {
        if (monitorState.length === 0)
            return null
        return monitorState[Math.max(0, Math.min(selectedIndex, monitorState.length - 1))]
    }

    function applyTheme() {
        let t = backend.theme
        bg = t.background || bg
        panel = t.backgroundPanel || panel
        panelAlt = t.backgroundElement || panelAlt
        border = t.border || border
        borderActive = t.borderActive || borderActive
        textStrong = t.text || textStrong
        textSoft = t.textMuted || textSoft
        accent = t.primary || accent
        accentSoft = t.backgroundElement || accentSoft
        success = t.secondary || success
        danger = t.error || danger
    }

    function bounds() {
        if (monitorState.length === 0)
            return { minX: 0, minY: 0, maxX: 1920, maxY: 1080 }
        let minX = monitorState[0].layoutX
        let minY = monitorState[0].layoutY
        let maxX = monitorState[0].layoutX + monitorState[0].width / monitorState[0].scale
        let maxY = monitorState[0].layoutY + monitorState[0].height / monitorState[0].scale
        for (let i = 1; i < monitorState.length; i++) {
            let m = monitorState[i]
            let w = m.width / m.scale
            let h = m.height / m.scale
            minX = Math.min(minX, m.layoutX)
            minY = Math.min(minY, m.layoutY)
            maxX = Math.max(maxX, m.layoutX + w)
            maxY = Math.max(maxY, m.layoutY + h)
        }
        return { minX, minY, maxX, maxY }
    }

    function snapMonitor(index) {
        if (monitorState.length < 2)
            return
        let active = monitorState[index]
        let bestDist = 1e12
        let bestX = active.layoutX
        let bestY = active.layoutY
        for (let i = 0; i < monitorState.length; i++) {
            if (i === index)
                continue
            let other = monitorState[i]
            let otherW = other.width / other.scale
            let otherH = other.height / other.scale
            let activeW = active.width / active.scale
            let activeH = active.height / active.scale
            let candidates = [
                { x: other.layoutX - activeW, y: active.layoutY },
                { x: other.layoutX + otherW, y: active.layoutY },
                { x: active.layoutX, y: other.layoutY - activeH },
                { x: active.layoutX, y: other.layoutY + otherH },
                { x: other.layoutX, y: other.layoutY },
                { x: other.layoutX + (otherW - activeW) / 2, y: other.layoutY },
                { x: other.layoutX, y: other.layoutY + (otherH - activeH) / 2 }
            ]
            for (let candidate of candidates) {
                let dx = active.layoutX - candidate.x
                let dy = active.layoutY - candidate.y
                let dist = dx * dx + dy * dy
                if (dist < bestDist) {
                    bestDist = dist
                    bestX = Math.round(candidate.x)
                    bestY = Math.round(candidate.y)
                }
            }
        }
        active.layoutX = bestX
        active.layoutY = bestY
        monitorState = cloneData(monitorState)
    }

    Component.onCompleted: loadState()

    Connections {
        target: backend
        function onMonitorsChanged() {
            loadState()
        }
        function onThemeChanged() {
            applyTheme()
        }
        function onApplyFinished(message, ok) {
            statusText = message
            statusOk = ok
        }
    }

    header: ToolBar {
        background: Rectangle {
            color: panel
            border.color: border
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            ColumnLayout {
                spacing: 2
                Label {
                    text: "Hypr Monitors"
                    color: textStrong
                    font.pixelSize: 18
                    font.bold: true
                }
                Label {
                    text: "Stage layout changes visually, then apply them all at once"
                    color: textSoft
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            ChromeButton {
                text: "Refresh"
                onClicked: backend.refresh()
            }

            ChromeButton {
                text: "Apply"
                enabled: monitorState.length > 0
                onClicked: backend.apply(JSON.stringify(monitorState))
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 22
        anchors.topMargin: 88
        spacing: 22

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: panel
            border.color: border

            Item {
                id: preview
                anchors.fill: parent
                anchors.margins: 14

                readonly property var layoutBounds: bounds()
                readonly property real layoutWidth: Math.max(1, layoutBounds.maxX - layoutBounds.minX)
                readonly property real layoutHeight: Math.max(1, layoutBounds.maxY - layoutBounds.minY)
                readonly property real dynamicScale: Math.min((width - 90) / layoutWidth, (height - 90) / layoutHeight, 0.18)
                readonly property real offsetX: (width - (layoutWidth * dynamicScale)) / 2 - layoutBounds.minX * dynamicScale
                readonly property real offsetY: (height - (layoutHeight * dynamicScale)) / 2 - layoutBounds.minY * dynamicScale

                Rectangle {
                    anchors.fill: parent
                    color: panelAlt
                }

                Repeater {
                    model: monitorState
                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        width: (modelData.width / modelData.scale) * preview.dynamicScale
                        height: (modelData.height / modelData.scale) * preview.dynamicScale
                        x: modelData.layoutX * preview.dynamicScale + preview.offsetX
                        y: modelData.layoutY * preview.dynamicScale + preview.offsetY
                        color: index === selectedIndex ? accentSoft : "#243041"
                        border.width: index === selectedIndex ? 2 : 1
                        border.color: index === selectedIndex ? accent : border
                        z: index === selectedIndex ? 2 : 1

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            color: "#0f1520"
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.name
                                color: textStrong
                                font.bold: true
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.width + "x" + modelData.height + " @ " + modelData.refresh + "Hz"
                                color: textSoft
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            drag.target: parent
                            onPressed: selectedIndex = index
                            onPositionChanged: {
                                monitorState[index].layoutX = Math.round((parent.x - preview.offsetX) / preview.dynamicScale)
                                monitorState[index].layoutY = Math.round((parent.y - preview.offsetY) / preview.dynamicScale)
                            }
                            onReleased: snapMonitor(index)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            color: panel
            border.color: border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
                    color: panelAlt
                    border.color: border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4
                        Label {
                            text: selectedMonitor() ? selectedMonitor().name : "No monitor selected"
                            color: textStrong
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Label {
                            text: selectedMonitor() ? selectedMonitor().description : "Pick a monitor from the preview"
                            color: textSoft
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Label {
                    text: "Active monitor"
                    color: textSoft
                }

                ChromeCombo {
                    Layout.fillWidth: true
                    model: monitorState.map(m => m.name)
                    currentIndex: selectedIndex
                    onActivated: selectedIndex = currentIndex
                }

                Label {
                    text: "Mode"
                    color: textSoft
                }

                ChromeCombo {
                    Layout.fillWidth: true
                    model: selectedMonitor() ? selectedMonitor().availableModes.map(m => m.label) : []
                    onActivated: {
                        let mon = selectedMonitor()
                        if (!mon)
                            return
                        let mode = mon.availableModes[currentIndex]
                        mon.width = mode.width
                        mon.height = mode.height
                        mon.refresh = mode.refresh
                        monitorState = cloneData(monitorState)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Scale"
                        color: textSoft
                    }
                    SpinBox {
                        Layout.fillWidth: true
                        from: 1
                        to: 30
                        value: selectedMonitor() ? Math.round(selectedMonitor().scale * 10) : 10
                        onValueModified: {
                            let mon = selectedMonitor()
                            if (!mon)
                                return
                            mon.scale = value / 10.0
                            monitorState = cloneData(monitorState)
                        }
                        textFromValue: function(value) { return (value / 10.0).toFixed(1) }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Transform"
                        color: textSoft
                    }
                    ChromeCombo {
                        Layout.fillWidth: true
                        model: ["0", "1", "2", "3", "4", "5", "6", "7"]
                        currentIndex: selectedMonitor() ? selectedMonitor().transform : 0
                        onActivated: {
                            let mon = selectedMonitor()
                            if (!mon)
                                return
                            mon.transform = currentIndex
                            monitorState = cloneData(monitorState)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    color: panelAlt
                    border.color: border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4
                        Label {
                            text: "Apply model"
                            color: textStrong
                            font.bold: true
                        }
                        Label {
                            text: "Dragging only stages the preview. Nothing changes in Hyprland until you press Apply."
                            color: textSoft
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    ChromeButton {
                        text: "Reset"
                        Layout.fillWidth: true
                        onClicked: loadState()
                    }
                    ChromeButton {
                        text: "Snap"
                        Layout.fillWidth: true
                        enabled: monitorState.length > 1
                        onClicked: snapMonitor(selectedIndex)
                    }
                }

                Item { Layout.fillHeight: true }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: statusText
                    color: statusOk ? success : danger
                    visible: statusText.length > 0
                }
            }
        }
    }
}
