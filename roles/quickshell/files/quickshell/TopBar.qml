import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray

PanelWindow {
    id: barWindow
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    // THICKER BAR, MINIMAL MARGINS
    implicitHeight: 48
    margins { top: 8; bottom: 0; left: 4; right: 4 }
    
    // exclusiveZone = height (48) + top margin (4)
    exclusiveZone: 52
    color: "transparent"

    // Dynamic Matugen Palette
    MatugenColors {
        id: mocha
    }

    // --- State Variables ---
    
    // Triggers layout animations immediately to feel fast
    property bool isStartupReady: false
    Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
    
    // Prevents repeaters (Workspaces/Tray) from flickering on data updates
    property bool startupCascadeFinished: false
    Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
    
    property string timeStr: ""
    property string fullDateStr: ""
    property int typeInIndex: 0
    property string dateStr: fullDateStr.substring(0, typeInIndex)

    property string weatherIcon: ""
    property string weatherTemp: "--°"
    property string weatherHex: mocha.yellow
    
    property string wifiStatus: "Off"
    property string wifiIcon: "󰤮"
    property string wifiSsid: ""
    
    property string btStatus: "Off"
    property string btIcon: "󰂲"
    property string btDevice: ""
    
    property string volPercent: "0%"
    property string volIcon: "󰕾"
    property bool isMuted: false
    property string batPercent: "100%"
    property string batIcon: "󰁹"
    property string kbLayout: "us"
    
    property var workspacesData: []
    property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }

    // Derived properties for UI logic
    property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
    property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
    property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"

    // ==========================================
    // DATA FETCHING (PROCESSES & TIMERS)
    // ==========================================

    Process {
        id: wsDaemon
        command: ["bash", "-c", "~/.config/quickshell/workspaces.sh > /tmp/qs_workspaces.json"]
        running: true
    }

    Process {
        id: wsPoller
        command: ["bash", "-c", "tail -n 1 /tmp/qs_workspaces.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { barWindow.workspacesData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 100; running: true; repeat: true; onTriggered: wsPoller.running = true }

    Process {
        id: musicPoller
        command: ["bash", "-c", "cat /tmp/music_info.json 2>/dev/null || bash ~/.config/quickshell/music/music_info.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; onTriggered: musicPoller.running = true }

    // SLOW POLLER: Battery, WiFi, Bluetooth (Updates every 5 seconds)
    Process {
        id: slowSysPoller
        command: ["bash", "-c", `
            echo "$(~/.config/quickshell/sys_info.sh --wifi-status)"
            echo "$(~/.config/quickshell/sys_info.sh --wifi-icon)"
            echo "$(~/.config/quickshell/sys_info.sh --wifi-ssid)"
            echo "$(~/.config/quickshell/sys_info.sh --bt-status)"
            echo "$(~/.config/quickshell/sys_info.sh --bt-icon)"
            echo "$(~/.config/quickshell/sys_info.sh --bt-connected)"
            echo "$(~/.config/quickshell/sys_info.sh --battery-percent)"
            echo "$(~/.config/quickshell/sys_info.sh --battery-icon)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 8) {
                    barWindow.wifiStatus = lines[0];
                    barWindow.wifiIcon = lines[1];
                    barWindow.wifiSsid = lines[2];
                    barWindow.btStatus = lines[3];
                    barWindow.btIcon = lines[4];
                    barWindow.btDevice = lines[5];
                    barWindow.batPercent = lines[6];
                    barWindow.batIcon = lines[7];
                }
            }
        }
    }
    Timer { interval: 1500; running: true; repeat: true; triggeredOnStart: true; onTriggered: slowSysPoller.running = true }

    // FAST POLLER: Volume and Layout (Updates every 150ms for instant feedback)
    Process {
        id: fastSysPoller
        command: ["bash", "-c", `
            echo "$(~/.config/quickshell/sys_info.sh --volume)"
            echo "$(~/.config/quickshell/sys_info.sh --volume-icon)"
            echo "$(~/.config/quickshell/sys_info.sh --kb-layout)"
            echo "$(~/.config/quickshell/sys_info.sh --is-muted)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 4) {
                    barWindow.volPercent = lines[0];
                    barWindow.volIcon = lines[1];
                    barWindow.kbLayout = lines[2];
                    barWindow.isMuted = (lines[3].toLowerCase() === "true");
                }
            }
        }
    }
    Timer { interval: 150; running: true; repeat: true; triggeredOnStart: true; onTriggered: fastSysPoller.running = true }

    Process {
        id: weatherPoller
        command: ["bash", "-c", `
            echo "$(~/.config/quickshell/calendar/weather.sh --current-icon)"
            echo "$(~/.config/quickshell/calendar/weather.sh --current-temp)"
            echo "$(~/.config/quickshell/calendar/weather.sh --current-hex)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    barWindow.weatherIcon = lines[0];
                    barWindow.weatherTemp = lines[1];
                    barWindow.weatherHex = lines[2] || mocha.yellow;
                }
            }
        }
    }
    Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

    // Native Qt Time Formatting
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            barWindow.timeStr = Qt.formatDateTime(d, "hh:mm:ss AP");
            barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
            if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                barWindow.typeInIndex = barWindow.fullDateStr.length;
            }
        }
    }

    // Typewriter effect timer for the date
    Timer {
        id: typewriterTimer
        interval: 40
        running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
        repeat: true
        onTriggered: barWindow.typeInIndex += 1
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    Item {
        anchors.fill: parent

        // ---------------- LEFT ----------------
        RowLayout {
            id: leftLayout
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 

            // Decoupled Main Transition
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                x: leftLayout.showLayout ? 0 : -20
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }
            
            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: leftLayout.showLayout = true
            }

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            property int moduleHeight: 48

            // Search 
            Rectangle {
                property bool isHovered: searchMouse.containsMouse
                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                Layout.preferredHeight: parent.moduleHeight; Layout.preferredWidth: 48
                
                scale: isHovered ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "󰍉"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: 24
                    color: parent.isHovered ? mocha.blue : mocha.text
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["bash", "-c", "rofi -show drun"])
                }
            }

            // Notifications
            Rectangle {
                property bool isHovered: notifMouse.containsMouse
                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                Layout.preferredHeight: parent.moduleHeight; Layout.preferredWidth: 48
                
                scale: isHovered ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"; font.pixelSize: 18
                    color: parent.isHovered ? mocha.yellow : mocha.text
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: notifMouse
                    anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
                        if (mouse.button === Qt.RightButton) Quickshell.execDetached(["swaync-client", "-d"]);
                    }
                }
            }

            // Workspaces 
            Rectangle {
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                Layout.preferredHeight: parent.moduleHeight
                clip: true
                
                property real targetWidth: barWindow.workspacesData.length > 0 ? wsLayout.implicitWidth + 20 : 0
                Layout.preferredWidth: targetWidth
                visible: targetWidth > 0
                opacity: barWindow.workspacesData.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

                RowLayout {
                    id: wsLayout
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Repeater {
                        model: barWindow.workspacesData
                        delegate: Rectangle {
                            id: wsPill
                            property bool isHovered: wsPillMouse.containsMouse
                            
                            property real targetWidth: modelData.state === "active" ? 36 : 32
                            Layout.preferredWidth: targetWidth
                            Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            
                            Layout.preferredHeight: 32; radius: 10
                            
                            // IMPROVED WORKSPACE STATES - Clearer hierarchy for occupied vs empty
                            color: modelData.state === "active" 
                                    ? mocha.mauve 
                                    : (isHovered 
                                        ? Qt.rgba(mocha.surface2.r, mocha.surface2.g, mocha.surface2.b, 0.9) 
                                        : (modelData.state === "occupied" 
                                            ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.9) 
                                            : "transparent"))

                            // ADDED TACTILE SCALE ANIMATION ON HOVER
                            scale: isHovered && modelData.state !== "active" ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            
                            // Safe Instantiation Cascade logic
                            property bool initAnimTrigger: barWindow.startupCascadeFinished
                            opacity: initAnimTrigger ? 1 : 0
                            transform: Translate {
                                y: wsPill.initAnimTrigger ? 0 : 15
                                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                            }

                            Component.onCompleted: {
                                if (!barWindow.startupCascadeFinished) {
                                    animTimer.interval = index * 60;
                                    animTimer.start();
                                }
                            }

                            Timer {
                                id: animTimer
                                running: false
                                repeat: false
                                onTriggered: wsPill.initAnimTrigger = true
                            }
                            
                            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 250 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.id
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                font.weight: modelData.state === "active" ? Font.Black : (modelData.state === "occupied" ? Font.Bold : Font.Medium)
                                
                                // IMPROVED TEXT CONTRAST - Pop occupied text to true text color, fade empty out
                                color: modelData.state === "active" 
                                        ? mocha.crust 
                                        : (isHovered 
                                            ? mocha.text 
                                            : (modelData.state === "occupied" ? mocha.text : mocha.overlay0))
                                        
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                            MouseArea {
                                id: wsPillMouse
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/qs_manager.sh " + modelData.id])
                            }
                        }
                    }
                }
            }

            // Media Player 
            Rectangle {
                id: mediaBox
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                Layout.preferredHeight: parent.moduleHeight
                clip: true 
                
                property real targetWidth: barWindow.isMediaActive ? mediaLayoutContainer.width + 24 : 0
                Layout.preferredWidth: targetWidth
                visible: Layout.preferredWidth > 0 

                Behavior on targetWidth { NumberAnimation { duration: 1400; easing.type: Easing.OutExpo } }
                
                Item {
                    id: mediaLayoutContainer
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    height: parent.height
                    width: innerMediaLayout.implicitWidth

                    RowLayout {
                        id: innerMediaLayout
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        
                        MouseArea {
                            id: mediaInfoMouse
                            Layout.preferredWidth: infoLayout.implicitWidth
                            Layout.fillHeight: true
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/qs_manager.sh toggle music"])
                            
                            RowLayout {
                                id: infoLayout
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                
                                scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                                Rectangle {
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 8; color: mocha.surface1
                                    border.width: barWindow.musicData.status === "Playing" ? 1 : 0
                                    border.color: mocha.mauve
                                    clip: true
                                    Image { 
                                        anchors.fill: parent; 
                                        source: barWindow.musicData.artUrl || ""; 
                                        fillMode: Image.PreserveAspectCrop 
                                    }
                                    
                                    // NEW: Dimmed slightly by tinting with the primary mauve accent, matching the weather icon
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.2)
                                    }
                                }
                                ColumnLayout {
                                    spacing: -2
                                    Layout.preferredWidth: 180 
                                    
                                    Text { 
                                        text: barWindow.musicData.title; 
                                        font.family: "JetBrainsMono Nerd Font"; 
                                        font.weight: Font.Black; 
                                        font.pixelSize: 13; 
                                        color: mocha.text; // Fixed contrast
                                        elide: Text.ElideRight; 
                                        Layout.fillWidth: true
                                    }
                                    Text { 
                                        text: barWindow.musicData.timeStr; 
                                        font.family: "JetBrainsMono Nerd Font"; 
                                        font.weight: Font.Black; 
                                        font.pixelSize: 10; 
                                        color: mocha.subtext0;
                                        elide: Text.ElideRight;
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Item { 
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; 
                                Text { 
                                    anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: 26; 
                                    color: prevMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: prevMouse.containsMouse ? 1.1 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                MouseArea { id: prevMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "previous"]) } 
                            }
                            Item { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; 
                                Text { 
                                    anchors.centerIn: parent; text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: 30; 
                                    color: playMouse.containsMouse ? mocha.green : mocha.text; 
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: playMouse.containsMouse ? 1.15 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                MouseArea { id: playMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "play-pause"]) } 
                            }
                            Item { 
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; 
                                Text { 
                                    anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: 26; 
                                    color: nextMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: nextMouse.containsMouse ? 1.1 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                MouseArea { id: nextMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "next"]) } 
                            }
                        }
                    }
                }
            }
        }

        // ---------------- CENTER ----------------
        Rectangle {
            id: centerBox
            anchors.centerIn: parent
            property bool isHovered: centerMouse.containsMouse
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
            radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
            height: 48
            
            width: centerLayout.implicitWidth + 36
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            
            // Decoupled Center Startup Transition
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                y: centerBox.showLayout ? 0 : -20
                Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
            }

            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: centerBox.showLayout = true
            }

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            // Hover Scaling
            scale: isHovered ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            Behavior on color { ColorAnimation { duration: 250 } }
            
            MouseArea {
                id: centerMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/qs_manager.sh toggle calendar"])
            }

            RowLayout {
                id: centerLayout
                anchors.centerIn: parent
                spacing: 24

                // Clockbox
                ColumnLayout {
                    spacing: -2
                    Text { text: barWindow.timeStr; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.weight: Font.Black; color: mocha.blue }
                    Text { text: barWindow.dateStr; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: mocha.subtext0 }
                }

                // Weatherbox
                RowLayout {
                    spacing: 8
                    Text { 
                        text: barWindow.weatherIcon; 
                        font.family: "Iosevka Nerd Font"; 
                        font.pixelSize: 24; 
                        // Dimmed slightly by tinting the raw hex with the primary mauve accent
                        color: Qt.tint(barWindow.weatherHex, Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)) 
                    }
                    Text { text: barWindow.weatherTemp; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17; font.weight: Font.Black; color: mocha.peach }
                }
            }
        }

        // ---------------- RIGHT ----------------
        RowLayout {
            id: rightLayout
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // Decoupled Right Startup Animation
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                x: rightLayout.showLayout ? 0 : 20
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }
            
            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: rightLayout.showLayout = true
            }

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            // Dedicated System Tray Pill
            Rectangle {
                height: 48
                radius: 14
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                border.width: 1
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                
                property real targetWidth: trayRepeater.count > 0 ? trayLayout.implicitWidth + 24 : 0
                Layout.preferredWidth: targetWidth
                Behavior on targetWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                
                visible: targetWidth > 0
                opacity: targetWidth > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                RowLayout {
                    id: trayLayout
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        id: trayRepeater
                        model: SystemTray.items
                        delegate: Image {
                            id: trayIcon
                            source: modelData.icon || ""
                            fillMode: Image.PreserveAspectFit
                            
                            sourceSize: Qt.size(18, 18)
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Layout.alignment: Qt.AlignVCenter
                            
                            property bool isHovered: trayMouse.containsMouse
                            property bool initAnimTrigger: barWindow.startupCascadeFinished
                            opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
                            scale: initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0

                            Component.onCompleted: {
                                if (!barWindow.startupCascadeFinished) {
                                    trayAnimTimer.interval = index * 50;
                                    trayAnimTimer.start();
                                }
                            }
                            Timer {
                                id: trayAnimTimer
                                running: false
                                repeat: false
                                onTriggered: trayIcon.initAnimTrigger = true
                            }

                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                            QsMenuAnchor {
                                id: menuAnchor
                                anchor.window: barWindow
                                anchor.item: trayIcon
                                menu: modelData.menu
                            }

                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        modelData.activate();
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        modelData.secondaryActivate();
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (modelData.menu) {
                                            menuAnchor.open();
                                        } else if (typeof modelData.contextMenu === "function") {
                                            modelData.contextMenu(mouse.x, mouse.y);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // System Elements Pill
            Rectangle {
                height: 48
                radius: 14
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                border.width: 1
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                
                property real targetWidth: sysLayout.implicitWidth + 20
                Layout.preferredWidth: targetWidth
                Behavior on targetWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                RowLayout {
                    id: sysLayout
                    anchors.centerIn: parent
                    spacing: 8 

                    property int pillHeight: 34

                    // KB
                    Rectangle {
                        property bool isHovered: kbMouse.containsMouse
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight;
                        
                        property real targetWidth: kbLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout { id: kbLayoutRow; anchors.centerIn: parent; spacing: 8
                            Text { text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: parent.parent.isHovered ? mocha.text : mocha.overlay2 }
                            Text { text: barWindow.kbLayout; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Black; color: mocha.text }
                        }
                        MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true }
                    }

                    // WiFi 
                    Rectangle {
                        id: wifiPill
                        property bool isHovered: wifiMouse.containsMouse
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight; 
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        
                        // Vibrant, guaranteed gradient contrast
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: barWindow.isWifiOn ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: mocha.blue }
                                GradientStop { position: 1.0; color: Qt.lighter(mocha.blue, 1.3) }
                            }
                        }

                        property real targetWidth: wifiLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout { id: wifiLayoutRow; anchors.centerIn: parent; spacing: 8
                            Text { text: barWindow.wifiIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: barWindow.isWifiOn ? mocha.base : mocha.subtext0 }
                            Text { text: barWindow.isWifiOn ? (barWindow.wifiSsid !== "" ? barWindow.wifiSsid : "On") : "Off"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Black; color: barWindow.isWifiOn ? mocha.base : mocha.text; Layout.maximumWidth: 100; elide: Text.ElideRight }
                        }
                        MouseArea { id: wifiMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/qs_manager.sh toggle network wifi"]) }
                    }

                    // Bluetooth 
                    Rectangle {
                        id: btPill
                        property bool isHovered: btMouse.containsMouse
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight
                        clip: true
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        
                        // Vibrant, guaranteed gradient contrast
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: barWindow.isBtOn ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: mocha.mauve }
                                GradientStop { position: 1.0; color: Qt.lighter(mocha.mauve, 1.3) }
                            }
                        }

                        property real targetWidth: btLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout { id: btLayoutRow; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12; spacing: barWindow.btDevice !== "" ? 8 : 0
                            Text { text: barWindow.btIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: barWindow.isBtOn ? mocha.base : mocha.subtext0 }
                            Text { visible: barWindow.btDevice !== ""; text: barWindow.btDevice; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Black; color: barWindow.isBtOn ? mocha.base : mocha.text; Layout.maximumWidth: 100; elide: Text.ElideRight }
                        }
                        MouseArea { id: btMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/qs_manager.sh toggle network bt"]) }
                    }

                    // Volume
                    Rectangle {
                        property bool isHovered: volMouse.containsMouse
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : (barWindow.isMuted ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4))
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight;
                        
                        property real targetWidth: volLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout { id: volLayoutRow; anchors.centerIn: parent; spacing: 8
                            Text { text: barWindow.volIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: barWindow.isMuted ? mocha.overlay0 : mocha.peach }
                            Text { 
                                text: barWindow.volPercent; 
                                font.family: "JetBrainsMono Nerd Font"; 
                                font.pixelSize: 13; 
                                font.weight: Font.Black; 
                                color: barWindow.isMuted ? mocha.overlay0 : mocha.text; 
                                font.strikeout: barWindow.isMuted 
                            }
                        }
                        MouseArea { id: volMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["pavucontrol"]) }
                    }

                    // Battery
                    Rectangle {
                        property bool isHovered: batMouse.containsMouse
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4); 
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight;
                        
                        property real targetWidth: batLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout { id: batLayoutRow; anchors.centerIn: parent; spacing: 8
                            Text { text: barWindow.batIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: parseInt(barWindow.batPercent) < 20 && barWindow.batIcon !== "󰂄" ? mocha.red : mocha.green }
                            Text { text: barWindow.batPercent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Black; color: mocha.text }
                        }
                        MouseArea { id: batMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/qs_manager.sh toggle battery"]) }
                    }
                }
            }
        }
    }
}
