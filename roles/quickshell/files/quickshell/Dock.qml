import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: dockWindow
    WlrLayershell.namespace: "qsdock"
    
    anchors {
        bottom: true
        left: true
        right: true
    }
    
    // FIX 2: Added a + 50 buffer to the height. 
    // This expands the invisible window boundary upwards so tooltips and popups don't get clipped.
    implicitHeight: dockContainer.height + settingsPanel.height + 70
    margins { bottom: 8 }
    
    exclusiveZone: 0 
    color: "transparent"
    
    focusable: true

    MatugenColors {
        id: mocha
    }

    // --- State Variables ---
    property bool isStartupReady: false
    Timer { interval: 10; running: true; onTriggered: dockWindow.isStartupReady = true }

    property var appsData: []
    property bool isSettingsOpen: false
    property string searchText: ""

    property var filteredApps: {
        let dummy = appsData; 
        let result = dummy.slice();

        if (searchText !== "") {
            let lowerSearch = searchText.toLowerCase();
            result = result.filter(app => app.name.toLowerCase().includes(lowerSearch));
        }
        
        return result.sort(function(a, b) {
            if (a.pinned === b.pinned) {
                return a.name.localeCompare(b.name);
            }
            return a.pinned ? -1 : 1;
        });
    }

    property var pinnedApps: {
        let pinned = [];
        for (let i = 0; i < appsData.length; i++) {
            if (appsData[i].pinned) pinned.push(appsData[i]);
        }
        return pinned;
    }

    // ==========================================
    // DATA FETCHING 
    // ==========================================
    Process {
        id: appPoller
        command: ["bash", "-c", "~/.config/quickshell/dock_backend.sh get"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { dockWindow.appsData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }
    
    Timer { interval: 100; running: true; repeat: false; onTriggered: appPoller.running = true }

    function toggleApp(appName) {
        let newArray = [];
        for (let i = 0; i < dockWindow.appsData.length; i++) {
            let item = Object.assign({}, dockWindow.appsData[i]); 
            if (item.name === appName) {
                item.pinned = !item.pinned;
            }
            newArray.push(item);
        }
        dockWindow.appsData = newArray; 

        let safeName = appName.replace(/'/g, "'\\''");
        Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/dock_backend.sh toggle '" + safeName + "'"]);
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    Item {
        anchors.fill: parent

        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                dockWindow.isSettingsOpen = false;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Alt || event.key === Qt.Key_Control) {
                return;
            }

            // FIX 1: Only catch typing IF the settings window is already manually opened.
            if (dockWindow.isSettingsOpen && !searchInput.activeFocus && event.text.length > 0) {
                searchInput.forceActiveFocus();
                searchInput.text += event.text;
                event.accepted = true;
            }
        }

        // ---------------- SETTINGS SLIDE OUT ----------------
        Rectangle {
            id: settingsPanel
            anchors.bottom: dockContainer.top
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            
            width: 400
            
            height: isSettingsOpen ? 400 : 0
            visible: height > 0
            clip: true
            
            color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.95)
            radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)
            
            opacity: isSettingsOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 8
                    color: Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.8)
                    border.width: 1
                    border.color: searchInput.activeFocus ? mocha.mauve : Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 16
                            color: searchInput.activeFocus ? mocha.mauve : mocha.text
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Search..."
                            placeholderTextColor: mocha.subtext0 
                            color: mocha.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            background: Item {} 
                            onTextChanged: dockWindow.searchText = text
                            
                            Keys.onEscapePressed: {
                                dockWindow.isSettingsOpen = false;
                                dockWindow.forceActiveFocus(); 
                            }
                            
                            Connections {
                                target: dockWindow
                                function onIsSettingsOpenChanged() {
                                    if (!dockWindow.isSettingsOpen) searchInput.text = "";
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: dockWindow.filteredApps
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 42
                        radius: 8
                        color: settingsItemMouse.containsMouse ? Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.5) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        transform: Translate { x: settingsItemMouse.containsMouse ? 6 : 0 }
                        Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                        Item {
                            anchors.fill: parent

                            Image {
                                id: appIcon
                                source: "image://icon/" + modelData.icon
                                sourceSize: Qt.size(24, 24)
                                width: 24; height: 24
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: mocha.text
                                anchors.left: appIcon.right
                                anchors.leftMargin: 12
                                anchors.right: checkIndicator.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: checkIndicator
                                width: 20
                                height: 20
                                radius: 10
                                border.width: 2
                                border.color: modelData.pinned ? mocha.mauve : mocha.surface2
                                color: modelData.pinned ? mocha.mauve : "transparent"
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 12
                                    color: mocha.base
                                    opacity: modelData.pinned ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                            }
                        }

                        MouseArea {
                            id: settingsItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                dockWindow.toggleApp(modelData.name)
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }

        // ---------------- MAIN DOCK ----------------
        Rectangle {
            id: dockContainer
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            
            property bool isHovered: dockMouse.containsMouse
            
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
            radius: 24
            border.width: 1 
            border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
            height: 56
            
            width: dockLayout.implicitWidth + 32
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on color { ColorAnimation { duration: 250 } }

            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                y: dockContainer.showLayout ? 0 : 20
                Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
            }
            Timer {
                running: dockWindow.isStartupReady
                interval: 10
                onTriggered: dockContainer.showLayout = true
            }
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            MouseArea {
                id: dockMouse
                anchors.fill: parent
                hoverEnabled: true
            }

            RowLayout {
                id: dockLayout
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: dockWindow.pinnedApps
                    delegate: Item {
                        id: dockAppDelegate
                        property bool itemHovered: appMouseArea.containsMouse
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        
                        Item {
                            anchors.fill: parent
                            scale: appMouseArea.pressed ? 0.85 : (itemHovered ? 1.15 : 1.0)
                            Behavior on scale { 
                                NumberAnimation { 
                                    duration: appMouseArea.pressed ? 50 : 250; 
                                    easing.type: appMouseArea.pressed ? Easing.OutQuad : Easing.OutBack 
                                } 
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: itemHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.9) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                                border.width: 1
                                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, itemHovered ? 0.15 : 0.05)
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }

                            Image {
                                anchors.centerIn: parent
                                source: "image://icon/" + modelData.icon
                                sourceSize: Qt.size(28, 28)
                                width: 28; height: 28
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 10
                            width: tooltipText.implicitWidth + 16
                            height: 28
                            radius: 6
                            color: mocha.surface0
                            border.width: 1
                            border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)
                            
                            // Hide tooltip if the context menu is open
                            opacity: (parent.itemHovered && !contextMenu.visible) ? 1 : 0
                            transform: Translate { y: parent.itemHovered ? 0 : 5 }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }
                            
                            Text {
                                id: tooltipText
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: mocha.text
                            }
                        }

                        // FIX 4: Custom Right-Click Context Menu
                        Popup {
                            id: contextMenu
                            width: 160
                            height: menuColumn.implicitHeight + 16
                            padding: 8
                            
                            // Center horizontally above the icon
                            x: (parent.width - width) / 2
                            y: -height - 15
                            
                            enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
                            exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }
                            
                            background: Rectangle {
                                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.95)
                                radius: 12
                                border.width: 1
                                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)
                            }

                            ColumnLayout {
                                id: menuColumn
                                anchors.fill: parent
                                spacing: 4

                                // Open Button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 6
                                    color: openCtxMouse.containsMouse ? Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.8) : "transparent"
                                    
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                        Text { text: "󰝰"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: mocha.text }
                                        Text { text: "Open"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: mocha.text; Layout.fillWidth: true }
                                    }
                                    MouseArea {
                                        id: openCtxMouse; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { 
                                            contextMenu.close(); 
                                            if (dockWindow.isSettingsOpen) dockWindow.isSettingsOpen = false;
                                            Quickshell.execDetached(["bash", "-c", modelData.exec]); 
                                        }
                                    }
                                }

                                // Unpin Button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 6
                                    color: unpinCtxMouse.containsMouse ? Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.8) : "transparent"
                                    
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                        Text { text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: mocha.red }
                                        Text { text: "Unpin"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: mocha.red; Layout.fillWidth: true }
                                    }
                                    MouseArea {
                                        id: unpinCtxMouse; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { 
                                            contextMenu.close(); 
                                            dockWindow.toggleApp(modelData.name); 
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: appMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            // Accept both buttons so right click doesn't fall through
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    if (dockWindow.isSettingsOpen) dockWindow.isSettingsOpen = false;
                                    Quickshell.execDetached(["bash", "-c", modelData.exec]);
                                } else if (mouse.button === Qt.RightButton) {
                                    contextMenu.open();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 24
                    color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)
                    visible: dockWindow.pinnedApps.length > 0
                }

                Item {
                    id: gearContainer
                    property bool btnHovered: settingsMouse.containsMouse
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: dockWindow.isSettingsOpen ? mocha.surface2 : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.6)
                        
                        opacity: gearContainer.btnHovered || dockWindow.isSettingsOpen ? 1 : 0
                        scale: gearContainer.btnHovered ? 1.15 : 1.0
                        
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 22
                        opacity: gearContainer.btnHovered || dockWindow.isSettingsOpen ? 1.0 : 0.6
                        color: mocha.text
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent 
                        hoverEnabled: true
                        onClicked: dockWindow.isSettingsOpen = !dockWindow.isSettingsOpen
                    }
                }
            }
        }
    }
}
