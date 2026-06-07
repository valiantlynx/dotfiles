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
    property color border: "#2b3648"
    property color textStrong: "#edf3ff"
    property color textSoft: "#a7b7cc"
    property color accent: "#79a8ff"
    property color accentSoft: "#223a68"
    property color success: "#8fd19e"
    property color danger: "#ff9a9a"
    property real snapGuideX: -1
    property real snapGuideY: -1

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
        textStrong = t.text || textStrong
        textSoft = t.textMuted || textSoft
        accent = t.primary || accent
        accentSoft = t.accent || accentSoft
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
        snapGuideX = -1
        snapGuideY = -1
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
                    snapGuideX = bestX
                    snapGuideY = bestY
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
                    font.pixelSize: 23
                    font.bold: true
                }
                Label {
                    text: "Stage layout changes visually, then apply them all at once"
                    color: textSoft
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Refresh"
                onClicked: backend.refresh()
            }

            Button {
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
            radius: 24
            color: panel
            border.color: border

            Item {
                id: preview
                anchors.fill: parent
                anchors.margins: 22

                readonly property var layoutBounds: bounds()
                readonly property real layoutWidth: Math.max(1, layoutBounds.maxX - layoutBounds.minX)
                readonly property real layoutHeight: Math.max(1, layoutBounds.maxY - layoutBounds.minY)
                readonly property real dynamicScale: Math.min((width - 110) / layoutWidth, (height - 110) / layoutHeight, 0.22)
                readonly property real offsetX: (width - (layoutWidth * dynamicScale)) / 2 - layoutBounds.minX * dynamicScale
                readonly property real offsetY: (height - (layoutHeight * dynamicScale)) / 2 - layoutBounds.minY * dynamicScale

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: panelAlt
                }

                Repeater {
                    model: 260
                    delegate: Rectangle {
                        width: 2
                        height: 2
                        radius: 1
                        color: "#253246"
                        x: 16 + (index % 20) * ((preview.width - 32) / 20)
                        y: 16 + Math.floor(index / 20) * ((preview.height - 32) / 13)
                        opacity: 0.35
                    }
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
                        radius: 16
                        color: index === selectedIndex ? accentSoft : "#243041"
                        border.width: index === selectedIndex ? 2 : 1
                        border.color: index === selectedIndex ? accent : "#44546a"
                        z: index === selectedIndex ? 2 : 1

                        Behavior on x {
                            enabled: !dragArea.drag.active
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                        Behavior on y {
                            enabled: !dragArea.drag.active
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 10
                            radius: 10
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
                            id: dragArea
                            anchors.fill: parent
                            drag.target: parent
                            onPressed: selectedIndex = index
                            onPositionChanged: {
                                monitorState[index].layoutX = Math.round((parent.x - preview.offsetX) / preview.dynamicScale)
                                monitorState[index].layoutY = Math.round((parent.y - preview.offsetY) / preview.dynamicScale)
                                snapMonitor(index)
                            }
                            onReleased: {
                                snapMonitor(index)
                                snapGuideX = -1
                                snapGuideY = -1
                            }
                        }
                    }
                }

                Rectangle {
                    visible: snapGuideX >= 0
                    width: 2
                    height: preview.height - 20
                    x: snapGuideX * preview.dynamicScale + preview.offsetX
                    y: 10
                    radius: 1
                    color: accent
                    opacity: 0.45
                }

                Rectangle {
                    visible: snapGuideY >= 0
                    width: preview.width - 20
                    height: 2
                    x: 10
                    y: snapGuideY * preview.dynamicScale + preview.offsetY
                    radius: 1
                    color: accent
                    opacity: 0.45
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            radius: 24
            color: panel
            border.color: border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
                    radius: 16
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

                ComboBox {
                    Layout.fillWidth: true
                    model: monitorState.map(m => m.name)
                    currentIndex: selectedIndex
                    onActivated: selectedIndex = currentIndex
                }

                Label {
                    text: "Mode"
                    color: textSoft
                }

                ComboBox {
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
                    ComboBox {
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
                    radius: 16
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
                    Button {
                        text: "Reset"
                        Layout.fillWidth: true
                        onClicked: loadState()
                    }
                    Button {
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
