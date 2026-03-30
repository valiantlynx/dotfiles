import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: masterWindow
    title: "qs-master"
    color: "transparent"
    
    // Always mapped to prevent Wayland from destroying the surface and Hyprland from auto-centering!
    visible: true 

    // Push it off-screen the moment the component loads using Hyprland's dispatcher
    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact -5000 -5000,title:^(qs-master)$"`]);
    }

    property int screenW: 1920
    property int screenH: 1080

    // Monitor offset — updated dynamically before each widget open
    // so popups appear on the focused monitor, not always monitor 0
    property int monitorX: 0
    property int monitorY: 0

    property string currentActive: "hidden" 
    onCurrentActiveChanged: {
        Quickshell.execDetached(["bash", "-c", "echo '" + currentActive + "' > /tmp/qs_active_widget"]);
    }

    property bool isVisible: false
    property string activeArg: ""
    property bool disableMorph: false 
    property bool isWallpaperTransition: false 

    // Dynamic duration to allow fast opening but keep morphing smooth
    property int morphDuration: 500

    // Safe park coordinates to avoid cursor traps
    property int currentX: -5000
    property int currentY: -5000

    property real animW: 1
    property real animH: 1

    // Layouts use coordinates relative to the monitor (0,0 = top-left of focused monitor)
    // monitorX/monitorY are added when dispatching hyprctl move commands
    property var layouts: {
        "battery":   { w: 480, h: 760, x: screenW - 500, y: 70, comp: "battery/BatteryPopup.qml" },
        "calendar":  { w: 1450, h: 750, x: 235, y: 70, comp: "calendar/CalendarPopup.qml" },
        "music":     { w: 700, h: 620, x: 12, y: 70, comp: "music/MusicPopup.qml" },
        "network":   { w: 900, h: 700, x: screenW - 920, y: 70, comp: "network/NetworkPopup.qml" },
        "stewart":   { w: 800, h: 600, x: Math.floor((screenW/2)-(800/2)), y: Math.floor((screenH/2)-(600/2)), comp: "stewart/stewart.qml" },
        "wallpaper": { w: screenW, h: 650, x: 0, y: Math.floor((screenH/2)-(650/2)), comp: "wallpaper/WallpaperPicker.qml" },
        "monitors":  { w: 850, h: 580, x: Math.floor((screenW/2)-(850/2)), y: Math.floor((screenH/2)-(580/2)), comp: "monitors/MonitorPopup.qml" },
        "focustime": { w: 900, h: 720, x: Math.floor((screenW/2)-(900/2)), y: Math.floor((screenH/2)-(720/2)), comp: "focustime/FocusTimePopup.qml" },
        "hidden":    { w: 1, h: 1, x: -5000, y: -5000, comp: "" } 
    }

    // Helper: absolute x/y for a layout (layout coords + monitor offset)
    function absX(lx) { return lx + monitorX; }
    function absY(ly) { return ly + monitorY; }
    implicitWidth: animW
    implicitHeight: animH

    onIsVisibleChanged: {
        if (isVisible && typeof masterWindow.requestActivate === "function") masterWindow.requestActivate();
    }

    Item {
        anchors.fill: parent
        clip: true 

        opacity: masterWindow.isVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: masterWindow.isWallpaperTransition ? 150 : (masterWindow.morphDuration === 500 ? 300 : 200); easing.type: Easing.InOutSine } }

        // INNER FIXED CONTAINER
        Item {
            anchors.fill: parent

            StackView {
                id: widgetStack
                anchors.fill: parent
                focus: true
                
                // Key bubbling catch-all.
                Keys.onEscapePressed: {
                    Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/qs_manager.sh", "close"])
                    event.accepted = true
                }

                onCurrentItemChanged: {
                    if (currentItem) currentItem.forceActiveFocus();
                }

                // Subtler transitions to respect wide layouts like the wallpaper picker
                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutExpo }
                        NumberAnimation { property: "scale"; from: 0.98; to: 1.0; duration: 400; easing.type: Easing.OutBack }
                    }
                }
                replaceExit: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 300; easing.type: Easing.InExpo }
                        NumberAnimation { property: "scale"; from: 1.0; to: 1.02; duration: 300; easing.type: Easing.InExpo }
                    }
                }
            }
        }
    }

    function switchWidget(newWidget, arg) {
        let involvesWallpaper = (newWidget === "wallpaper" || currentActive === "wallpaper");
        masterWindow.isWallpaperTransition = involvesWallpaper;

        if (newWidget === "hidden") {
            if (currentActive !== "hidden" && layouts[currentActive]) {
                masterWindow.morphDuration = 250; // FAST CLOSE
                masterWindow.disableMorph = false;
                let t = layouts[currentActive];
                let cx = absX(Math.floor(t.x + (t.w/2)));
                let cy = absY(Math.floor(t.y + (t.h/2)));
                
                masterWindow.animW = 1;
                masterWindow.animH = 1;
                masterWindow.isVisible = false;
                
                Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact ${cx} ${cy},title:^(qs-master)$"`]);
                delayedClear.start();
            }
        } else {
            if (currentActive === "hidden") {
                masterWindow.morphDuration = 250; // FAST INITIAL OPEN
                masterWindow.disableMorph = false;
                let t = layouts[newWidget];
                let cx = absX(Math.floor(t.x + (t.w / 2)));
                let cy = absY(Math.floor(t.y + (t.h / 2)));

                masterWindow.animW = 1;
                masterWindow.animH = 1;
                masterWindow.implicitWidth = 1;
                masterWindow.implicitHeight = 1;

                Quickshell.execDetached(["bash", "-c", `hyprctl dispatch movewindowpixel "exact ${cx} ${cy},title:^(qs-master)$"`]);

                prepTimer.newWidget = newWidget;
                prepTimer.newArg = arg;
                prepTimer.start();
                
            } else {
                masterWindow.morphDuration = 500; // SMOOTH MORPH BETWEEN WIDGETS
                if (involvesWallpaper) {
                    masterWindow.disableMorph = true;
                    masterWindow.isVisible = false; 
                    teleportFadeOutTimer.newWidget = newWidget;
                    teleportFadeOutTimer.newArg = arg;
                    teleportFadeOutTimer.start();
                } else {
                    masterWindow.disableMorph = false;
                    executeSwitch(newWidget, arg, false);
                }
            }
        }
    }

    Timer {
        id: prepTimer
        interval: 50
        property string newWidget: ""
        property string newArg: ""
        onTriggered: executeSwitch(newWidget, newArg, false)
    }

    Timer {
        id: teleportFadeOutTimer
        interval: 150 
        property string newWidget: ""
        property string newArg: ""
        onTriggered: {
            let t = layouts[newWidget];

            masterWindow.currentActive = newWidget;
            masterWindow.activeArg = newArg;

            masterWindow.animW = t.w;
            masterWindow.animH = t.h;
            masterWindow.implicitWidth = t.w;
            masterWindow.implicitHeight = t.h;
            masterWindow.currentX = absX(t.x);
            masterWindow.currentY = absY(t.y);

            Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact ${t.w} ${t.h},title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact ${absX(t.x)} ${absY(t.y)},title:^(qs-master)$"`]);

            let props = newWidget === "wallpaper" ? { "widgetArg": newArg } : {};
            widgetStack.replace(t.comp, props, StackView.Immediate);

            teleportFadeInTimer.newWidget = newWidget;
            teleportFadeInTimer.newArg = newArg;
            teleportFadeInTimer.start();
        }
    }

    Timer {
        id: teleportFadeInTimer
        interval: 50 
        property string newWidget: ""
        property string newArg: ""
        onTriggered: {
            masterWindow.isVisible = true; 
            if (newWidget !== "wallpaper") resetMorphTimer.start();
        }
    }

    Timer {
        id: resetMorphTimer
        interval: masterWindow.morphDuration 
        onTriggered: masterWindow.disableMorph = false
    }

    function executeSwitch(newWidget, arg, immediate) {
        masterWindow.currentActive = newWidget;
        masterWindow.activeArg = arg;
        
        let t = layouts[newWidget];
        masterWindow.animW = t.w;
        masterWindow.animH = t.h;
        masterWindow.implicitWidth = t.w;
        masterWindow.implicitHeight = t.h;
        masterWindow.currentX = absX(t.x);
        masterWindow.currentY = absY(t.y);
        
        Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact ${t.w} ${t.h},title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact ${absX(t.x)} ${absY(t.y)},title:^(qs-master)$"`]);
        
        masterWindow.isVisible = true;
        
        let props = newWidget === "wallpaper" ? { "widgetArg": arg } : {};

        if (immediate) {
            widgetStack.replace(t.comp, props, StackView.Immediate);
        } else {
            widgetStack.replace(t.comp, props);
        }
    }

    // --- Monitor offset query ---
    // Before opening a widget, we query the focused monitor's x,y offset
    // so popups appear on the correct screen in multi-monitor setups.
    property string pendingCmd: ""
    property string pendingArg: ""

    Process {
        id: monitorQuery
        command: ["bash", "-c", "hyprctl monitors -j | python3 -c \"import json,sys; m=[x for x in json.load(sys.stdin) if x['focused']]; print(m[0]['x'],m[0]['y']) if m else print(0,0)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(" ");
                if (parts.length >= 2) {
                    masterWindow.monitorX = parseInt(parts[0]) || 0;
                    masterWindow.monitorY = parseInt(parts[1]) || 0;
                }
                // Now process the pending command with correct monitor offset
                let cmd = masterWindow.pendingCmd;
                let arg = masterWindow.pendingArg;
                masterWindow.pendingCmd = "";
                masterWindow.pendingArg = "";

                if (cmd === "close") {
                    switchWidget("hidden", "");
                } else if (layouts[cmd]) {
                    delayedClear.stop();
                    if (masterWindow.isVisible && masterWindow.currentActive === cmd) {
                        switchWidget("hidden", "");
                    } else {
                        switchWidget(cmd, arg);
                    }
                }
            }
        }
    }

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: { if (!ipcPoller.running) ipcPoller.running = true; }
    }

    Process {
        id: ipcPoller
        command: ["bash", "-c", "if [ -f /tmp/qs_widget_state ]; then cat /tmp/qs_widget_state; rm /tmp/qs_widget_state; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rawCmd = this.text.trim();
                if (rawCmd === "") return;

                let parts = rawCmd.split(":");
                let cmd = parts[0];
                let arg = parts.length > 1 ? parts[1] : "";

                if (cmd === "close") {
                    // Close doesn't need monitor query
                    switchWidget("hidden", "");
                } else if (layouts[cmd]) {
                    // Query focused monitor before opening
                    masterWindow.pendingCmd = cmd;
                    masterWindow.pendingArg = arg;
                    monitorQuery.running = true;
                }
            }
        }
    }

    Timer {
        id: delayedClear
        interval: masterWindow.isWallpaperTransition ? 150 : masterWindow.morphDuration 
        onTriggered: {
            masterWindow.currentActive = "hidden";
            widgetStack.clear();
            masterWindow.disableMorph = false;
            
            // Banished safely back to the shadow realm off-screen
            let cmd = `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact -5000 -5000,title:^(qs-master)$"`;
            Quickshell.execDetached(["bash", "-c", cmd]);
        }
    }
}
