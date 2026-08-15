// LookaRetro — custom Pegasus Frontend theme.
//
// A gamepad-first, two-level launcher with a Nintendo pixel-art + "Lord of
// the Rings" aesthetic (gold ring, Shire green, Mordor dark, scanlines) and
// the LookaDev mark in the header.
//
//   HOME  -> horizontal carousel of systems (collections)
//   GAMES -> box-art grid + detail panel for the selected system
//
// Controls (Pegasus defaults):
//   D-pad / arrows : move        A (accept) : open system / launch game
//   B (cancel)     : back        START       : Pegasus settings menu
//   L1 / R1        : prev / next system
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

    property var currentCollection: api.collections.count > 0 ? api.collections.get(platformIndex) : null
    property var gamesModel: currentCollection ? currentCollection.games : null
    property var currentGame: (gamesModel && gamesModel.count > 0) ? gamesModel.get(gameIndex) : null

    property real cardW: vpx(320)
    property real cardH: vpx(430)

    // LOTR-inspired palette: gold (the ring), shire green, cyan, elvish, mordor, amber, silver, teal
    function accent(i) {
        var palette = ["#e6c453", "#4a9c54", "#5fd0e8", "#8b6fd4", "#c05a4a", "#f6c177", "#9fb0bd", "#3ec6a8"]
        return palette[i % palette.length]
    }
    function currentAccent() { return accent(platformIndex) }

    property color gold: "#e6c453"
    property color green: "#4a9c54"
    property color silver: "#9fb0bd"

    // ---- navigation ------------------------------------------------------
    function moveHome(dx) {
        var n = api.collections.count
        if (n === 0) return
        platformIndex = (platformIndex + dx + n) % n
        homeList.currentIndex = platformIndex
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
        homeList.positionViewAtIndex(platformIndex, ListView.Contain)
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
        if (currentGame.players > 1) parts.push(currentGame.players + " players")
        return parts.join("  \u00b7  ")
    }

    function hints() {
        if (view === "home")
            return "\u25c0 \u25b6 navegar    A abrir    L1/R1 sistema    START menu"
        return "\u25c0 \u25b6 \u25b2 \u25bc navegar    A jogar    B voltar    L1/R1 sistema    START menu"
    }

    Component.onCompleted: {
        if (api.memory.has("platformIndex")) {
            var i = api.memory.get("platformIndex")
            if (i >= 0 && i < api.collections.count) platformIndex = i
        }
        homeList.currentIndex = platformIndex
    }

    // ---- input -----------------------------------------------------------
    Keys.onPressed: {
        if (event.isAutoRepeat) return

        if (view === "home") {
            if (event.key === Qt.Key_Left)        { event.accepted = true; moveHome(-1) }
            else if (event.key === Qt.Key_Right)  { event.accepted = true; moveHome(1) }
            else if (api.keys.isAccept(event))    { event.accepted = true; openCollection() }
            else if (api.keys.isPrevPage(event))  { event.accepted = true; moveHome(-1) }
            else if (api.keys.isNextPage(event))  { event.accepted = true; moveHome(1) }
        } else {
            if (event.key === Qt.Key_Left)        { event.accepted = true; moveGames(-1, 0) }
            else if (event.key === Qt.Key_Right)  { event.accepted = true; moveGames(1, 0) }
            else if (event.key === Qt.Key_Up)     { event.accepted = true; moveGames(0, -1) }
            else if (event.key === Qt.Key_Down)   { event.accepted = true; moveGames(0, 1) }
            else if (api.keys.isAccept(event))    { event.accepted = true; launchCurrent() }
            else if (api.keys.isCancel(event))    { event.accepted = true; goHome() }
            else if (api.keys.isPrevPage(event))  { event.accepted = true; switchPlatform(-1) }
            else if (api.keys.isNextPage(event))  { event.accepted = true; switchPlatform(1) }
        }
    }

    // ---- background ------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0d1117" }
            GradientStop { position: 0.5; color: "#0a0e13" }
            GradientStop { position: 1.0; color: "#080b0f" }
        }
    }

    // Blurred screenshot/background of the selected game (games view only).
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
            radius: 42
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#e60a0e13" }
                GradientStop { position: 1.0; color: "#f20a0e13" }
            }
        }
    }

    // ---- header ----------------------------------------------------------
    Row {
        anchors { top: parent.top; left: parent.left; margins: vpx(34) }
        spacing: vpx(18)

        // The One Ring encircling the LookaDev mark
        Item {
            width: vpx(52); height: vpx(52)
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                border.width: vpx(3)
                border.color: root.gold
                color: "#00000000"
            }
            Image {
                anchors.centerIn: parent
                width: vpx(40); height: vpx(40)
                source: "assets/lookadev.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: vpx(4)
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
            Text {
                text: "um console para a todos governar"
                font.family: global.fonts.condensed
                font.pixelSize: vpx(14)
                font.letterSpacing: 1
                color: root.silver
            }
        }
    }

    // ---- HOME: system carousel -------------------------------------------
    ListView {
        id: homeList
        anchors.fill: parent
        anchors.topMargin: vpx(150)
        visible: view === "home"

        model: api.collections
        orientation: ListView.Horizontal
        spacing: vpx(28)
        focus: false

        currentIndex: root.platformIndex
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - cardW) / 2
        preferredHighlightEnd: (width + cardW) / 2
        highlightMoveDuration: 180

        delegate: Component {
            Item {
                width: cardW
                height: cardH
                scale: ListView.isCurrentItem ? 1.06 : 0.92
                opacity: ListView.isCurrentItem ? 1.0 : 0.6
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180 } }

                property bool isOpenSource: modelData.shortName === "open-source"
                property color cardColor: isOpenSource ? "#00e676" : root.accent(index)

                Rectangle {
                    anchors.fill: parent
                    radius: vpx(8)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cardColor }
                        GradientStop { position: 0.45; color: "#171c26" }
                        GradientStop { position: 1.0; color: "#0e1218" }
                    }
                    border.width: ListView.isCurrentItem ? vpx(3) : vpx(1)
                    border.color: ListView.isCurrentItem ? cardColor : "#2a303c"
                }

                // pixel-art "screws" in the corners
                Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: "#3a4352"; anchors { top: parent.top; left: parent.left; margins: vpx(12) } }
                Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: "#3a4352"; anchors { top: parent.top; right: parent.right; margins: vpx(12) } }
                Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: "#3a4352"; anchors { bottom: parent.bottom; left: parent.left; margins: vpx(12) } }
                Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); color: "#3a4352"; anchors { bottom: parent.bottom; right: parent.right; margins: vpx(12) } }

                Rectangle {
                    visible: isOpenSource
                    anchors { top: parent.top; right: parent.right; topMargin: vpx(16); rightMargin: vpx(16) }
                    width: badgeText.width + vpx(20)
                    height: vpx(30)
                    radius: vpx(4)
                    color: "#00e676"
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: "\u2193 DOWNLOAD"
                        font.family: pixelFont.name
                        font.pixelSize: vpx(9)
                        color: "#06210f"
                    }
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(150) }
                    text: modelData.shortName.toUpperCase()
                    font.family: pixelFont.name
                    font.pixelSize: vpx(26)
                    color: "#f2f4f8"
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(196) }
                    text: modelData.name
                    font.family: global.fonts.condensed
                    font.pixelSize: vpx(17)
                    color: "#aeb4c2"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width - vpx(28)
                    wrapMode: Text.Wrap
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.verticalCenter; topMargin: vpx(70) }
                    text: modelData.games.count + (modelData.games.count === 1 ? " jogo" : " jogos")
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(16)
                    color: cardColor
                }
            }
        }
    }

    // ---- GAMES: box-art grid --------------------------------------------
    GridView {
        id: gamesGrid
        anchors {
            top: parent.top; topMargin: vpx(130)
            bottom: hintBar.top; bottomMargin: vpx(20)
            left: parent.left; leftMargin: vpx(48)
            right: detailPanel.left; rightMargin: vpx(32)
        }
        visible: view === "games"

        model: root.gamesModel
        cellWidth: vpx(180)
        cellHeight: vpx(252)
        focus: false
        currentIndex: root.gameIndex

        delegate: Component {
            Item {
                width: gamesGrid.cellWidth - vpx(16)
                height: gamesGrid.cellHeight - vpx(16)
                scale: GridView.isCurrentItem ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                Rectangle {
                    id: boxFrame
                    anchors { fill: parent; bottomMargin: vpx(38) }
                    radius: vpx(6)
                    color: "#141824"
                    border.width: GridView.isCurrentItem ? vpx(3) : vpx(1)
                    border.color: GridView.isCurrentItem ? root.gold : "#2a303c"

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
                    anchors { left: parent.left; right: parent.right; top: boxFrame.bottom; topMargin: vpx(4) }
                    text: modelData.title
                    color: GridView.isCurrentItem ? root.gold : "#aeb4c2"
                    font.family: global.fonts.condensed
                    font.pixelSize: vpx(16)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ---- detail panel ----------------------------------------------------
    Item {
        id: detailPanel
        anchors {
            top: parent.top; topMargin: vpx(130)
            bottom: hintBar.top; bottomMargin: vpx(20)
            right: parent.right; rightMargin: vpx(48)
        }
        width: vpx(400)
        visible: view === "games"

        Column {
            anchors.fill: parent
            spacing: vpx(18)

            Rectangle {
                width: vpx(56); height: vpx(6)
                radius: vpx(2)
                color: root.gold
            }

            Text {
                width: parent.width
                text: currentGame ? currentGame.title : ""
                font.family: pixelFont.name
                font.pixelSize: vpx(14)
                lineHeight: 1.5
                color: root.gold
                wrapMode: Text.Wrap
            }

            Rectangle {
                visible: currentCollection && currentCollection.shortName === "open-source"
                width: dlBadgeText.width + vpx(20)
                height: vpx(30)
                radius: vpx(4)
                color: "#00e676"
                Text {
                    id: dlBadgeText
                    anchors.centerIn: parent
                    text: "\u2193 download autom\u00e1tico"
                    font.family: pixelFont.name
                    font.pixelSize: vpx(9)
                    color: "#06210f"
                }
            }

            Text {
                width: parent.width
                text: metaLine()
                font.family: global.fonts.sans
                font.pixelSize: vpx(16)
                color: root.silver
            }

            Text {
                width: parent.width
                visible: currentGame && currentGame.rating > 0
                text: currentGame ? "\u2605  " + Math.round(currentGame.rating * 100) + "%" : ""
                font.family: pixelFont.name
                font.pixelSize: vpx(12)
                color: root.gold
            }

            Text {
                width: parent.width
                text: currentGame ? currentGame.summary : ""
                font.family: global.fonts.sans
                font.pixelSize: vpx(17)
                color: "#c6ccda"
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 7
            }

            Text {
                width: parent.width
                visible: currentGame && currentGame.genre
                text: currentGame ? currentGame.genre.toUpperCase() : ""
                font.family: global.fonts.condensed
                font.pixelSize: vpx(14)
                font.letterSpacing: 2
                color: root.green
            }
        }
    }

    // ---- hint bar --------------------------------------------------------
    Rectangle {
        id: hintBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(60)
        color: "#0b0f15"

        Text {
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: vpx(48) }
            text: hints()
            font.family: pixelFont.name
            font.pixelSize: vpx(10)
            color: root.silver
        }

        Text {
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: vpx(48) }
            text: "\u25cf " + root.currentAccent()
            font.family: pixelFont.name
            font.pixelSize: vpx(10)
            color: root.currentAccent()
        }
    }

    // ---- CRT scanline overlay -------------------------------------------
    Image {
        anchors.fill: parent
        source: "assets/scanlines.png"
        fillMode: Image.Tile
        opacity: 0.55
        visible: true
    }
}
