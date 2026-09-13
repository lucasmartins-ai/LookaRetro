// LookaRetro — custom Pegasus Frontend theme (v1.3).
//
// A gamepad-first, two-level launcher with a Nintendo pixel-art + "Lord of
// the Rings" aesthetic (gold ring, Shire green, Mordor dark, scanlines) and
// the LookaDev mark in the header.
//
//   HOME  -> horizontal carousel of systems (collections) with centered gold-ring focus
//   GAMES -> box-art grid + detail panel for the selected system
//
// Controls (Pegasus defaults):
//   D-pad / arrows : move        A (accept) : open system / launch game
//   B (cancel)     : back/exit   START      : Pegasus settings menu
//   L1 / R1        : prev / next system
//   ESC            : safe exit dialog (returns to desktop, never shuts down computer)
//
// Uses only QtQuick + QtGraphicalEffects (no QtQuick.Controls), which are
// bundled with Pegasus. The `api`, `global` objects and `vpx()` helper are
// provided by Pegasus itself. Assets in ./assets are bundled with the theme.

import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    FontLoader { id: pixelFont; source: "assets/PressStart2P.ttf" }

    // ---- state -----------------------------------------------------------
    property int platformIndex: 0
    property int gameIndex: 0
    property string view: "home"        // "home" | "games"

    // Safe exit modal state
    property bool showExitDialog: false
    property int exitSelectedBtn: 0     // 0 = [ ✕ SAIR DO LOOKARETRO ], 1 = [ ◀ CONTINUAR JOGANDO ]

    // Real-time clock & date
    property string currentTime: "00:00"
    property string currentDate: ""

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            var h = d.getHours()
            var m = d.getMinutes()
            currentTime = (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)

            var dias = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
            var meses = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
            currentDate = dias[d.getDay()] + ", " + d.getDate() + " " + meses[d.getMonth()]
        }
    }

    property var currentCollection: api.collections.count > 0 ? api.collections.get(platformIndex) : null
    property var gamesModel: currentCollection ? currentCollection.games : null
    property var currentGame: (gamesModel && gamesModel.count > 0) ? gamesModel.get(gameIndex) : null

    property real cardW: vpx(330)
    property real cardH: vpx(440)

    // LOTR-inspired palette: gold (the ring), shire green, cyan, elvish, mordor, amber, silver, teal
    function accent(i) {
        var palette = ["#e6c453", "#4a9c54", "#5fd0e8", "#8b6fd4", "#c05a4a", "#f6c177", "#9fb0bd", "#3ec6a8"]
        return palette[i % palette.length]
    }
    function currentAccent() { return accent(platformIndex) }

    property color gold: "#f5c542"
    property color goldBright: "#ffe072"
    property color green: "#10b981"
    property color silver: "#9fb0bd"
    property color darkBg: "#0b0e14"
    property color cardBg: "#131822"

    // ---- navigation ------------------------------------------------------
    function moveHome(dx) {
        var n = api.collections.count
        if (n === 0) return
        platformIndex = (platformIndex + dx + n) % n
        homeList.currentIndex = platformIndex
        homeList.positionViewAtIndex(platformIndex, ListView.Center)
        saveState()
    }

    function openCollection() {
        if (!currentCollection) return
        gameIndex = 0
        view = "games"
        gamesGrid.currentIndex = 0
        gamesGrid.positionViewAtIndex(0, GridView.Contain)
    }

    function goHome() {
        view = "home"
        homeList.currentIndex = platformIndex
        homeList.positionViewAtIndex(platformIndex, ListView.Center)
    }

    function switchPlatform(dx) {
        moveHome(dx)
        if (view === "games") {
            gameIndex = 0
            gamesGrid.currentIndex = 0
            gamesGrid.positionViewAtIndex(0, GridView.Contain)
        }
    }

    function gridColumns() {
        return Math.max(1, Math.floor(gamesGrid.width / gamesGrid.cellWidth))
    }

    function moveGames(dx, dy) {
        if (!gamesModel || gamesModel.count === 0) return
        var n = gamesModel.count
        if (dx !== 0) {
            gameIndex = (gameIndex + dx + n) % n
        } else if (dy !== 0) {
            var cols = gridColumns()
            var idx = gameIndex + dy * cols
            if (idx < 0) idx = 0
            if (idx >= n) idx = n - 1
            gameIndex = idx
        }
        gamesGrid.currentIndex = gameIndex
        gamesGrid.positionViewAtIndex(gameIndex, GridView.Contain)
    }

    function launchCurrent() {
        if (currentGame) {
            api.memory.set("platformIndex", platformIndex)
            currentGame.launch()
        }
    }

    function saveState() {
        api.memory.set("platformIndex", platformIndex)
    }

    function backdropSource() {
        if (!currentGame) return ""
        var s = currentGame.assets.screenshot
        if (s && s.length > 0) return s
        var b = currentGame.assets.background
        if (b && b.length > 0) return b
        return ""
    }

    function metaLine() {
        if (!currentGame) return ""
        var parts = []
        if (currentGame.releaseYear) parts.push(String(currentGame.releaseYear))
        if (currentGame.developer) parts.push(currentGame.developer)
        if (currentGame.players > 1) parts.push(currentGame.players + "P")
        return parts.join("  \u00b7  ")
    }

    function hints() {
        if (showExitDialog)
            return "\u25c0 \u25b6 alternar op\u00e7\u00e3o    A confirmar    B cancelar"
        if (view === "home")
            return "\u25c0 \u25b6 navegar    A abrir sistema    L1/R1 sistema    ESC/B sair    START menu"
        return "\u25c0 \u25b6 \u25b2 \u25bc navegar    A jogar    B voltar    L1/R1 sistema    START menu"
    }

    Component.onCompleted: {
        if (api.memory.has("platformIndex")) {
            var i = api.memory.get("platformIndex")
            if (i >= 0 && i < api.collections.count) platformIndex = i
        }
        homeList.currentIndex = platformIndex
        homeList.positionViewAtIndex(platformIndex, ListView.Center)
    }

    // ---- input -----------------------------------------------------------
    Keys.onPressed: {
        if (event.isAutoRepeat) return

        // 1. When Safe Exit Dialog is open, trap and control dialog inputs
        if (showExitDialog) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                event.accepted = true
                exitSelectedBtn = (exitSelectedBtn === 0 ? 1 : 0)
            } else if (api.keys.isAccept(event) || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                event.accepted = true
                if (exitSelectedBtn === 0) {
                    Qt.quit()
                } else {
                    showExitDialog = false
                }
            } else if (api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                event.accepted = true
                showExitDialog = false
            }
            return
        }

        // 2. Normal View Navigation
        if (view === "home") {
            if (event.key === Qt.Key_Left)        { event.accepted = true; moveHome(-1) }
            else if (event.key === Qt.Key_Right)  { event.accepted = true; moveHome(1) }
            else if (api.keys.isAccept(event))    { event.accepted = true; openCollection() }
            else if (api.keys.isPrevPage(event))  { event.accepted = true; moveHome(-1) }
            else if (api.keys.isNextPage(event))  { event.accepted = true; moveHome(1) }
            else if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
                // Intercept Cancel/Escape on Home: open safe exit modal!
                event.accepted = true
                exitSelectedBtn = 0
                showExitDialog = true
            }
        } else {
            if (event.key === Qt.Key_Left)        { event.accepted = true; moveGames(-1, 0) }
            else if (event.key === Qt.Key_Right)  { event.accepted = true; moveGames(1, 0) }
            else if (event.key === Qt.Key_Up)     { event.accepted = true; moveGames(0, -1) }
            else if (event.key === Qt.Key_Down)   { event.accepted = true; moveGames(0, 1) }
            else if (api.keys.isAccept(event))    { event.accepted = true; launchCurrent() }
            else if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
                event.accepted = true
                goHome()
            }
            else if (api.keys.isPrevPage(event))  { event.accepted = true; switchPlatform(-1) }
            else if (api.keys.isNextPage(event))  { event.accepted = true; switchPlatform(1) }
        }
    }

    // ---- background ------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c1017" }
            GradientStop { position: 0.5; color: "#080b0f" }
            GradientStop { position: 1.0; color: "#05070a" }
        }
    }

    // Subtle atmospheric ambient background glow matching the current collection
    RadialGradient {
        anchors.fill: parent
        visible: view === "home"
        opacity: 0.18
        horizontalRadius: width * 0.65
        verticalRadius: height * 0.65
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.currentAccent() }
            GradientStop { position: 0.7; color: "#00000000" }
        }
    }

    // Blurred screenshot/background of the selected game (games view only)
    Item {
        anchors.fill: parent
        visible: view === "games"

        Image {
            id: backdropRaw
            anchors.fill: parent
            source: backdropSource()
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        FastBlur {
            anchors.fill: parent
            source: backdropRaw
            radius: 50
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#e8080b0f" }
                GradientStop { position: 1.0; color: "#f405070a" }
            }
        }
    }

    // ---- top header bar --------------------------------------------------
    Item {
        id: headerBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(88)

        // Brand / Logo (Left)
        Row {
            anchors { left: parent.left; leftMargin: vpx(36); verticalCenter: parent.verticalCenter }
            spacing: vpx(16)

            // The One Ring encircling the LookaDev mark with pulsing sheen
            Item {
                width: vpx(52); height: vpx(52)
                anchors.verticalCenter: parent.verticalCenter

                // Outer ambient gold glow
                Rectangle {
                    anchors.centerIn: parent
                    width: vpx(58); height: vpx(58)
                    radius: width / 2
                    color: "#30f5c542"
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation { from: 0.95; to: 1.08; duration: 1600; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.08; to: 0.95; duration: 1600; easing.type: Easing.InOutQuad }
                    }
                }

                // The Golden Ring
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    border.width: vpx(3)
                    border.color: root.gold
                    color: "#121722"
                }

                Image {
                    anchors.centerIn: parent
                    width: vpx(38); height: vpx(38)
                    source: "assets/lookadev.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(3)

                Row {
                    spacing: 0
                    Text {
                        text: "LOOKA"
                        font.family: pixelFont.name
                        font.pixelSize: vpx(18)
                        color: root.gold
                    }
                    Text {
                        text: "\u00b7RETRO"
                        font.family: pixelFont.name
                        font.pixelSize: vpx(18)
                        color: root.green
                    }
                }

                // Breadcrumb trail
                Row {
                    spacing: vpx(8)
                    Text {
                        text: view === "home" ? "CONSOLE RETRO" : (currentCollection ? currentCollection.name.toUpperCase() : "")
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(13)
                        font.letterSpacing: 1
                        font.bold: true
                        color: root.silver
                    }
                    Text {
                        visible: view === "games" && gamesModel
                        text: "\u00b7 " + (gamesModel ? gamesModel.count : 0) + " JOGOS"
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(13)
                        font.letterSpacing: 1
                        color: root.gold
                    }
                }
            }
        }

        // Action Buttons & Clock (Right)
        Row {
            anchors { right: parent.right; rightMargin: vpx(36); verticalCenter: parent.verticalCenter }
            spacing: vpx(18)

            // Breadcrumb button in games view to quickly go back
            Rectangle {
                visible: view === "games"
                width: backBtnText.width + vpx(24)
                height: vpx(36)
                radius: vpx(6)
                color: backArea.containsMouse ? "#202a3a" : "#141b27"
                border.width: vpx(1)
                border.color: backArea.containsMouse ? root.gold : "#2a3446"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: backBtnText
                    anchors.centerIn: parent
                    text: "\u25c0 VOLTAR AO MENU"
                    font.family: pixelFont.name
                    font.pixelSize: vpx(8)
                    color: backArea.containsMouse ? root.gold : root.silver
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: goHome()
                }
            }

            // Close / Exit button [ ✕ SAIR ]
            Rectangle {
                width: exitBtnText.width + vpx(22)
                height: vpx(36)
                radius: vpx(6)
                color: exitArea.containsMouse ? "#3b1517" : "#1a1215"
                border.width: vpx(1)
                border.color: exitArea.containsMouse ? "#ef4444" : "#4a2428"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: exitBtnText
                    anchors.centerIn: parent
                    text: "\u2715 SAIR"
                    font.family: pixelFont.name
                    font.pixelSize: vpx(9)
                    color: exitArea.containsMouse ? "#fca5a5" : "#c27478"
                }

                MouseArea {
                    id: exitArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        exitSelectedBtn = 0
                        showExitDialog = true
                    }
                }
            }

            // Vertical divider
            Rectangle {
                width: vpx(1); height: vpx(32)
                color: "#222a38"
                anchors.verticalCenter: parent.verticalCenter
            }

            // Live Clock & Date Badge
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(2)

                Text {
                    anchors.right: parent.right
                    text: currentTime
                    font.family: pixelFont.name
                    font.pixelSize: vpx(14)
                    color: root.gold
                }
                Text {
                    anchors.right: parent.right
                    text: currentDate
                    font.family: global.fonts.condensed
                    font.pixelSize: vpx(12)
                    color: root.silver
                    font.letterSpacing: 1
                }
            }
        }
    }

    // ---- HOME: Centered System Carousel ----------------------------------
    Item {
        id: homeContainer
        anchors {
            top: headerBar.bottom
            bottom: paginationBar.top
            left: parent.left
            right: parent.right
        }
        visible: view === "home"

        ListView {
            id: homeList
            anchors.fill: parent
            anchors.topMargin: vpx(20)
            anchors.bottomMargin: vpx(10)

            model: api.collections
            orientation: ListView.Horizontal
            spacing: vpx(34)
            focus: false

            currentIndex: root.platformIndex
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - cardW) / 2
            preferredHighlightEnd: (width + cardW) / 2
            highlightMoveDuration: 220

            delegate: Component {
                Item {
                    id: cardItem
                    width: cardW
                    height: cardH

                    readonly property bool isCurrent: ListView.isCurrentItem
                    readonly property bool isOpenSource: modelData.shortName === "open-source"
                    readonly property color themeColor: isOpenSource ? "#00e676" : root.accent(index)

                    scale: isCurrent ? 1.08 : 0.88
                    opacity: isCurrent ? 1.0 : 0.38
                    z: isCurrent ? 10 : 1

                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    // Golden halo glow for the selected card
                    Rectangle {
                        visible: cardItem.isCurrent
                        anchors.fill: parent
                        anchors.margins: vpx(-6)
                        radius: vpx(14)
                        color: "#00000000"
                        border.width: vpx(3)
                        border.color: root.goldBright
                        opacity: 0.85

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: cardItem.isCurrent
                            NumberAnimation { from: 0.55; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.0; to: 0.55; duration: 1000; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Main Card Body
                    Rectangle {
                        id: cardBody
                        anchors.fill: parent
                        radius: vpx(10)
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: cardItem.isCurrent ? cardItem.themeColor : "#18202c"
                            }
                            GradientStop {
                                position: cardItem.isCurrent ? 0.38 : 0.25
                                color: "#141a24"
                            }
                            GradientStop {
                                position: 1.0
                                color: "#0e131b"
                            }
                        }
                        border.width: cardItem.isCurrent ? vpx(3) : vpx(1)
                        border.color: cardItem.isCurrent ? root.gold : "#1e2636"
                    }

                    // Authentic Corner Screws (Nintendo Console Feel)
                    Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: cardItem.isCurrent ? root.gold : "#283244"; anchors { top: parent.top; left: parent.left; margins: vpx(12) } }
                    Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: cardItem.isCurrent ? root.gold : "#283244"; anchors { top: parent.top; right: parent.right; margins: vpx(12) } }
                    Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: cardItem.isCurrent ? root.gold : "#283244"; anchors { bottom: parent.bottom; left: parent.left; margins: vpx(12) } }
                    Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: cardItem.isCurrent ? root.gold : "#283244"; anchors { bottom: parent.bottom; right: parent.right; margins: vpx(12) } }

                    // SELECTION BADGE (Unmistakable: Only on the current card)
                    Rectangle {
                        visible: cardItem.isCurrent
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: vpx(14) }
                        width: badgeSelText.width + vpx(20)
                        height: vpx(26)
                        radius: vpx(13)
                        color: root.gold

                        Text {
                            id: badgeSelText
                            anchors.centerIn: parent
                            text: "\u25b6 SELECIONADO"
                            font.family: pixelFont.name
                            font.pixelSize: vpx(8)
                            font.bold: true
                            color: "#0c1017"
                        }
                    }

                    // Open source catalog download badge
                    Rectangle {
                        visible: cardItem.isOpenSource && !cardItem.isCurrent
                        anchors { top: parent.top; right: parent.right; topMargin: vpx(14); rightMargin: vpx(14) }
                        width: badgeDlText.width + vpx(14)
                        height: vpx(22)
                        radius: vpx(4)
                        color: "#00e676"
                        Text {
                            id: badgeDlText
                            anchors.centerIn: parent
                            text: "DOWNLOAD"
                            font.family: pixelFont.name
                            font.pixelSize: vpx(7)
                            color: "#06210f"
                        }
                    }

                    // System Short Name (e.g. SNES, N64, GBA)
                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(140) }
                        text: modelData.shortName.toUpperCase()
                        font.family: pixelFont.name
                        font.pixelSize: vpx(28)
                        color: cardItem.isCurrent ? "#ffffff" : "#7e889b"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // System Full Title
                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(195) }
                        text: modelData.name
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(18)
                        font.bold: true
                        color: cardItem.isCurrent ? "#dce2ee" : "#606b7d"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - vpx(36)
                        wrapMode: Text.Wrap
                    }

                    // Game count pill badge
                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: vpx(46) }
                        width: gameCountText.width + vpx(26)
                        height: vpx(34)
                        radius: vpx(17)
                        color: cardItem.isCurrent ? "#1c2434" : "#111622"
                        border.width: vpx(1)
                        border.color: cardItem.isCurrent ? cardItem.themeColor : "#202a3a"

                        Text {
                            id: gameCountText
                            anchors.centerIn: parent
                            text: modelData.games.count + (modelData.games.count === 1 ? " jogo" : " jogos")
                            font.family: global.fonts.sans
                            font.pixelSize: vpx(15)
                            font.bold: true
                            color: cardItem.isCurrent ? cardItem.themeColor : "#68758b"
                        }
                    }

                    // Press 'A' to open prompt (only on active card)
                    Row {
                        visible: cardItem.isCurrent
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: vpx(16) }
                        spacing: vpx(6)

                        Text {
                            text: "(A) ABRIR SISTEMA"
                            font.family: pixelFont.name
                            font.pixelSize: vpx(8)
                            color: root.gold
                        }
                    }

                    // Mouse Interaction
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cardItem.isCurrent) {
                                openCollection()
                            } else {
                                platformIndex = index
                                homeList.currentIndex = index
                                homeList.positionViewAtIndex(index, ListView.Center)
                                saveState()
                            }
                        }
                    }
                }
            }
        }

        // Left Navigation Arrow Button
        Rectangle {
            anchors { left: parent.left; leftMargin: vpx(18); verticalCenter: parent.verticalCenter }
            width: vpx(44); height: vpx(64)
            radius: vpx(8)
            color: leftArrowArea.containsMouse ? "#202a3c" : "#121824"
            border.width: vpx(1)
            border.color: leftArrowArea.containsMouse ? root.gold : "#263246"
            opacity: 0.85

            Text {
                anchors.centerIn: parent
                text: "\u25c0"
                font.family: pixelFont.name
                font.pixelSize: vpx(16)
                color: leftArrowArea.containsMouse ? root.gold : root.silver
            }

            MouseArea {
                id: leftArrowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: moveHome(-1)
            }
        }

        // Right Navigation Arrow Button
        Rectangle {
            anchors { right: parent.right; rightMargin: vpx(18); verticalCenter: parent.verticalCenter }
            width: vpx(44); height: vpx(64)
            radius: vpx(8)
            color: rightArrowArea.containsMouse ? "#202a3c" : "#121824"
            border.width: vpx(1)
            border.color: rightArrowArea.containsMouse ? root.gold : "#263246"
            opacity: 0.85

            Text {
                anchors.centerIn: parent
                text: "\u25b6"
                font.family: pixelFont.name
                font.pixelSize: vpx(16)
                color: rightArrowArea.containsMouse ? root.gold : root.silver
            }

            MouseArea {
                id: rightArrowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: moveHome(1)
            }
        }
    }

    // ---- HOME: System Pagination & Position Indicator --------------------
    Item {
        id: paginationBar
        anchors { bottom: hintBar.top; left: parent.left; right: parent.right }
        height: vpx(48)
        visible: view === "home"

        Column {
            anchors.centerIn: parent
            spacing: vpx(8)

            // Horizontal pill dots
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: vpx(8)

                Repeater {
                    model: api.collections.count
                    Rectangle {
                        readonly property bool isCur: index === root.platformIndex
                        width: isCur ? vpx(28) : vpx(8)
                        height: vpx(8)
                        radius: vpx(4)
                        color: isCur ? root.gold : "#2c3647"

                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 160 } }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                platformIndex = index
                                homeList.currentIndex = index
                                homeList.positionViewAtIndex(index, ListView.Center)
                                saveState()
                            }
                        }
                    }
                }
            }

            // System position label
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SISTEMA " + (root.platformIndex + 1) + " DE " + api.collections.count +
                      (currentCollection ? "  \u00b7  " + currentCollection.name.toUpperCase() : "")
                font.family: pixelFont.name
                font.pixelSize: vpx(9)
                color: root.gold
            }
        }
    }

    // ---- GAMES: box-art grid ---------------------------------------------
    GridView {
        id: gamesGrid
        anchors {
            top: headerBar.bottom; topMargin: vpx(10)
            bottom: hintBar.top; bottomMargin: vpx(20)
            left: parent.left; leftMargin: vpx(48)
            right: detailPanel.left; rightMargin: vpx(32)
        }
        visible: view === "games"

        model: root.gamesModel
        cellWidth: vpx(180)
        cellHeight: vpx(255)
        focus: false
        currentIndex: root.gameIndex

        delegate: Component {
            Item {
                id: gameItem
                width: gamesGrid.cellWidth - vpx(16)
                height: gamesGrid.cellHeight - vpx(16)

                readonly property bool isCurrentGame: GridView.isCurrentItem

                scale: isCurrentGame ? 1.08 : (gameArea.containsMouse ? 1.03 : 1.0)
                opacity: isCurrentGame ? 1.0 : (gameArea.containsMouse ? 0.95 : 0.78)
                z: isCurrentGame ? 10 : 1

                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 140 } }

                // Outer golden bracket glow for the selected game
                Rectangle {
                    visible: gameItem.isCurrentGame
                    anchors.fill: boxFrame
                    anchors.margins: vpx(-4)
                    radius: vpx(10)
                    color: "#00000000"
                    border.width: vpx(2)
                    border.color: root.goldBright
                }

                Rectangle {
                    id: boxFrame
                    anchors { fill: parent; bottomMargin: vpx(40) }
                    radius: vpx(8)
                    color: gameItem.isCurrentGame ? "#1a2232" : "#111520"
                    border.width: gameItem.isCurrentGame ? vpx(3) : vpx(1)
                    border.color: gameItem.isCurrentGame ? root.gold : "#232d3e"

                    Image {
                        anchors { fill: parent; margins: vpx(6) }
                        source: modelData.assets.boxFront
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                    }

                    Text {
                        anchors { fill: parent; margins: vpx(10) }
                        text: modelData.title
                        color: "#8b92a3"
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(15)
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        visible: modelData.assets.boxFront === ""
                    }
                }

                Text {
                    anchors { left: parent.left; right: parent.right; top: boxFrame.bottom; topMargin: vpx(6) }
                    text: modelData.title
                    color: gameItem.isCurrentGame ? root.gold : "#abb3c4"
                    font.family: global.fonts.condensed
                    font.pixelSize: vpx(15)
                    font.bold: gameItem.isCurrentGame
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: gameArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (gameItem.isCurrentGame) {
                            launchCurrent()
                        } else {
                            gameIndex = index
                            gamesGrid.currentIndex = index
                        }
                    }
                }
            }
        }
    }

    // ---- GAMES: detail panel ---------------------------------------------
    Item {
        id: detailPanel
        anchors {
            top: headerBar.bottom; topMargin: vpx(10)
            bottom: hintBar.top; bottomMargin: vpx(20)
            right: parent.right; rightMargin: vpx(48)
        }
        width: vpx(420)
        visible: view === "games"

        Rectangle {
            anchors.fill: parent
            radius: vpx(12)
            color: "#e8111622"
            border.width: vpx(1)
            border.color: "#232c3d"

            Column {
                anchors.fill: parent
                anchors.margins: vpx(24)
                spacing: vpx(16)

                // Top decorative gold bar
                Rectangle {
                    width: vpx(64); height: vpx(5)
                    radius: vpx(2)
                    color: root.gold
                }

                // Game Title
                Text {
                    width: parent.width
                    text: currentGame ? currentGame.title : ""
                    font.family: pixelFont.name
                    font.pixelSize: vpx(15)
                    lineHeight: 1.4
                    color: root.gold
                    wrapMode: Text.Wrap
                }

                // Badges row (Year, Rating, Players)
                Row {
                    spacing: vpx(10)

                    // Rating badge
                    Rectangle {
                        visible: currentGame && currentGame.rating > 0
                        width: ratingText.width + vpx(16)
                        height: vpx(26)
                        radius: vpx(4)
                        color: "#2a2210"
                        border.width: vpx(1)
                        border.color: root.gold

                        Text {
                            id: ratingText
                            anchors.centerIn: parent
                            text: currentGame ? "\u2605 " + Math.round(currentGame.rating * 100) + "%" : ""
                            font.family: pixelFont.name
                            font.pixelSize: vpx(9)
                            color: root.gold
                        }
                    }

                    // Open source badge
                    Rectangle {
                        visible: currentCollection && currentCollection.shortName === "open-source"
                        width: dlBadgeText.width + vpx(16)
                        height: vpx(26)
                        radius: vpx(4)
                        color: "#00e676"
                        Text {
                            id: dlBadgeText
                            anchors.centerIn: parent
                            text: "\u2193 AUTO DOWNLOAD"
                            font.family: pixelFont.name
                            font.pixelSize: vpx(8)
                            font.bold: true
                            color: "#06210f"
                        }
                    }
                }

                // Metadata line
                Text {
                    width: parent.width
                    text: metaLine()
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(15)
                    color: root.silver
                }

                // Genre
                Text {
                    width: parent.width
                    visible: currentGame && currentGame.genre !== ""
                    text: currentGame ? currentGame.genre.toUpperCase() : ""
                    font.family: global.fonts.condensed
                    font.pixelSize: vpx(13)
                    font.letterSpacing: 2
                    color: root.green
                }

                // Divider line
                Rectangle {
                    width: parent.width
                    height: vpx(1)
                    color: "#202a3a"
                }

                // Game summary / description
                Text {
                    width: parent.width
                    text: currentGame ? (currentGame.summary || "Nenhuma descrição disponível.") : ""
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(16)
                    lineHeight: 1.35
                    color: "#c6ccda"
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 6
                }

                // Launch Game Action Prompt
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: vpx(52)
                    radius: vpx(8)
                    color: launchBtnArea.containsMouse ? "#1e7e42" : "#135d2f"
                    border.width: vpx(2)
                    border.color: root.green

                    Row {
                        anchors.centerIn: parent
                        spacing: vpx(10)

                        Text {
                            text: "(A)"
                            font.family: pixelFont.name
                            font.pixelSize: vpx(12)
                            color: root.gold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "JOGAR AGORA"
                            font.family: pixelFont.name
                            font.pixelSize: vpx(11)
                            font.bold: true
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: launchBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launchCurrent()
                    }
                }
            }
        }
    }

    // ---- bottom hint bar -------------------------------------------------
    Rectangle {
        id: hintBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(56)
        color: "#090d13"
        border.width: vpx(1)
        border.color: "#18202c"

        Text {
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: vpx(36) }
            text: hints()
            font.family: pixelFont.name
            font.pixelSize: vpx(9)
            color: root.silver
        }

        Row {
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: vpx(36) }
            spacing: vpx(12)

            Rectangle {
                width: vpx(10); height: vpx(10); radius: vpx(5)
                color: root.currentAccent()
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "LOOKARETRO v1.3"
                font.family: pixelFont.name
                font.pixelSize: vpx(9)
                color: root.gold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ---- SAFE EXIT CONFIRMATION MODAL ------------------------------------
    // Completely isolated modal that calls Qt.quit() cleanly.
    // IMPOSSIBLE to shut down or reboot the computer!
    Item {
        id: safeExitModal
        anchors.fill: parent
        visible: root.showExitDialog
        z: 9999

        // Darkened backdrop with mouse blocker
        Rectangle {
            anchors.fill: parent
            color: "#e605070a"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Clicking background dismisses dialog safely
                    root.showExitDialog = false
                }
            }
        }

        // Modal Dialog Box
        Rectangle {
            id: exitBox
            anchors.centerIn: parent
            width: vpx(580)
            height: vpx(340)
            radius: vpx(14)
            color: "#111624"
            border.width: vpx(3)
            border.color: root.gold

            // Corner Screws
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: root.gold; anchors { top: parent.top; left: parent.left; margins: vpx(12) } }
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: root.gold; anchors { top: parent.top; right: parent.right; margins: vpx(12) } }
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: root.gold; anchors { bottom: parent.bottom; left: parent.left; margins: vpx(12) } }
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: root.gold; anchors { bottom: parent.bottom; right: parent.right; margins: vpx(12) } }

            Column {
                anchors.fill: parent
                anchors.margins: vpx(28)
                spacing: vpx(20)

                // Dialog Header
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(12)

                    // The One Ring icon
                    Rectangle {
                        width: vpx(28); height: vpx(28); radius: width / 2
                        border.width: vpx(2); border.color: root.gold
                        color: "#00000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "FECHAR O LOOKARETRO"
                        font.family: pixelFont.name
                        font.pixelSize: vpx(14)
                        font.bold: true
                        color: root.gold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Explanatory Safety Message
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(8)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Deseja sair para a \u00c1rea de Trabalho?"
                        font.family: global.fonts.sans
                        font.pixelSize: vpx(18)
                        font.bold: true
                        color: "#f2f5fa"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "(O seu computador continuar\u00e1 ligado normalmente)"
                        font.family: global.fonts.sans
                        font.pixelSize: vpx(14)
                        color: "#8a96a8"
                    }
                }

                // Two Distinct, Unambiguous Buttons
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(20)

                    // Button 0: [ ✕ SAIR DO LOOKARETRO ]
                    Rectangle {
                        width: vpx(240)
                        height: vpx(54)
                        radius: vpx(8)

                        readonly property bool isSelected: root.exitSelectedBtn === 0

                        color: isSelected ? "#dc2626" : "#201216"
                        border.width: isSelected ? vpx(3) : vpx(1)
                        border.color: isSelected ? root.goldBright : "#451a22"
                        opacity: isSelected ? 1.0 : 0.45

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: vpx(8)

                            Text {
                                visible: parent.parent.isSelected
                                text: "\u25b6"
                                font.family: pixelFont.name
                                font.pixelSize: vpx(9)
                                color: "#ffffff"
                            }

                            Text {
                                text: "SAIR DO APP"
                                font.family: pixelFont.name
                                font.pixelSize: vpx(10)
                                font.bold: true
                                color: "#ffffff"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.exitSelectedBtn = 0
                            onClicked: Qt.quit()
                        }
                    }

                    // Button 1: [ ◀ CONTINUAR JOGANDO ]
                    Rectangle {
                        width: vpx(240)
                        height: vpx(54)
                        radius: vpx(8)

                        readonly property bool isSelected: root.exitSelectedBtn === 1

                        color: isSelected ? "#15803d" : "#111f18"
                        border.width: isSelected ? vpx(3) : vpx(1)
                        border.color: isSelected ? root.goldBright : "#1d382b"
                        opacity: isSelected ? 1.0 : 0.45

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: vpx(8)

                            Text {
                                visible: parent.parent.isSelected
                                text: "\u25b6"
                                font.family: pixelFont.name
                                font.pixelSize: vpx(9)
                                color: "#ffffff"
                            }

                            Text {
                                text: "VOLTAR AOS JOGOS"
                                font.family: pixelFont.name
                                font.pixelSize: vpx(10)
                                font.bold: true
                                color: "#ffffff"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.exitSelectedBtn = 1
                            onClicked: root.showExitDialog = false
                        }
                    }
                }

                // Controller helper legend
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u25c0 \u25b6 ALTERNAR    A CONFIRMAR    B CANCELAR"
                    font.family: pixelFont.name
                    font.pixelSize: vpx(8)
                    color: root.silver
                }
            }
        }
    }

    // ---- CRT scanline overlay --------------------------------------------
    Image {
        anchors.fill: parent
        source: "assets/scanlines.png"
        fillMode: Image.Tile
        opacity: 0.45
        visible: true
    }
}
