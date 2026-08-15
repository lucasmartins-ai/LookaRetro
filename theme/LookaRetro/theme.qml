// LookaRetro — custom Pegasus Frontend theme.
//
// A gamepad-first, two-level launcher:
//   HOME  -> horizontal carousel of systems (collections)
//   GAMES -> box-art grid + detail panel for the selected system
//
// Controls (Pegasus defaults):
//   D-pad / arrows : move        A (accept) : open system / launch game
//   B (cancel)     : back        START       : Pegasus settings menu
//   L1 / R1        : prev / next system
//
// Uses only QtQuick + QtGraphicalEffects (no QtQuick.Controls), which are
// bundled with Pegasus. The `api` and `global` objects and the `vpx()`
// helper are provided by Pegasus itself.

import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    // ---- state -----------------------------------------------------------
    property int platformIndex: 0
    property int gameIndex: 0
    property string view: "home"        // "home" | "games"

    property var currentCollection: api.collections.count > 0 ? api.collections.get(platformIndex) : null
    property var gamesModel: currentCollection ? currentCollection.games : null
    property var currentGame: (gamesModel && gamesModel.count > 0) ? gamesModel.get(gameIndex) : null

    property real cardW: vpx(320)
    property real cardH: vpx(430)

    function accent(i) {
        var palette = ["#00e5ff", "#ff2d95", "#7c4dff", "#00e676", "#ffab00", "#ff5252", "#18ffff", "#ff6d00"]
        return palette[i % palette.length]
    }
    function currentAccent() { return accent(platformIndex) }

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
            return "\u25c0  \u25b6  navegar    \u2022    A  abrir    \u2022    L1/R1  sistema    \u2022    START  menu"
        return "\u25c0  \u25b6  \u25b2  \u25bc  navegar    \u2022    A  jogar    \u2022    B  voltar    \u2022    L1/R1  sistema    \u2022    START  menu"
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
        color: "#0a0d14"
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
                GradientStop { position: 0.0; color: "#e60a0d14" }
                GradientStop { position: 1.0; color: "#f20a0d14" }
            }
        }
    }

    // ---- header ----------------------------------------------------------
    Row {
        anchors { top: parent.top; left: parent.left; margins: vpx(40) }
        spacing: 0
        Text {
            text: "LOOKA"
            font.family: global.fonts.condensedBold
            font.pixelSize: vpx(30)
            font.letterSpacing: 2
            color: "#e7eaf2"
        }
        Text {
            text: "RETRO"
            font.family: global.fonts.condensedBold
            font.pixelSize: vpx(30)
            font.letterSpacing: 2
            color: currentAccent()
        }
        Text {
            text: view === "home" ? "  \u2014  sistemas" : ("  \u2014  " + (currentCollection ? currentCollection.name : ""))
            font.family: global.fonts.condensed
            font.pixelSize: vpx(20)
            color: "#7f8797"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ---- HOME: system carousel -------------------------------------------
    ListView {
        id: homeList
        anchors.fill: parent
        anchors.topMargin: vpx(140)
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
                    radius: vpx(20)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cardColor }
                        GradientStop { position: 0.55; color: "#1b1f2e" }
                        GradientStop { position: 1.0; color: "#12151f" }
                    }
                    border.width: ListView.isCurrentItem ? vpx(3) : vpx(1)
                    border.color: ListView.isCurrentItem ? cardColor : "#2a2f3d"
                }

                Rectangle {
                    visible: isOpenSource
                    anchors { top: parent.top; right: parent.right; topMargin: vpx(16); rightMargin: vpx(16) }
                    width: badgeText.width + vpx(24)
                    height: vpx(32)
                    radius: vpx(16)
                    color: "#00e676"
                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: "\u2193 DOWNLOAD"
                        font.family: global.fonts.condensedBold
                        font.pixelSize: vpx(13)
                        font.letterSpacing: 1
                        color: "#06210f"
                    }
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(150) }
                    text: modelData.name.toUpperCase()
                    font.family: global.fonts.condensedBold
                    font.pixelSize: vpx(32)
                    color: "#f2f4f8"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width - vpx(24)
                    wrapMode: Text.Wrap
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.verticalCenter; topMargin: vpx(52) }
                    text: modelData.games.count + (modelData.games.count === 1 ? " jogo" : " jogos")
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(16)
                    color: "#aeb4c2"
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: vpx(26) }
                    text: modelData.shortName.toUpperCase()
                    font.family: global.fonts.condensed
                    font.pixelSize: vpx(14)
                    font.letterSpacing: 3
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
                    radius: vpx(12)
                    color: "#141824"
                    border.width: GridView.isCurrentItem ? vpx(3) : vpx(1)
                    border.color: GridView.isCurrentItem ? root.currentAccent() : "#2a2f3d"

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
                    color: GridView.isCurrentItem ? "#ffffff" : "#aeb4c2"
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
                radius: vpx(3)
                color: root.currentAccent()
            }

            Text {
                width: parent.width
                text: currentGame ? currentGame.title : ""
                font.family: global.fonts.condensedBold
                font.pixelSize: vpx(42)
                color: "#ffffff"
                wrapMode: Text.Wrap
            }

            Text {
                width: parent.width
                text: metaLine()
                font.family: global.fonts.sans
                font.pixelSize: vpx(16)
                color: "#9aa1b2"
            }

            Text {
                width: parent.width
                visible: currentGame && currentGame.rating > 0
                text: currentGame ? "\u2605  " + Math.round(currentGame.rating * 100) + "%" : ""
                font.family: global.fonts.condensedBold
                font.pixelSize: vpx(18)
                color: root.currentAccent()
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
                color: "#7f8797"
            }
        }
    }

    // ---- hint bar --------------------------------------------------------
    Rectangle {
        id: hintBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(64)
        color: "#0c0f16"

        Text {
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: vpx(48) }
            text: hints()
            font.family: global.fonts.condensed
            font.pixelSize: vpx(18)
            color: "#8b92a3"
        }

        Text {
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: vpx(48) }
            text: root.currentAccent()
            font.family: global.fonts.condensedBold
            font.pixelSize: vpx(18)
            color: root.currentAccent()
            opacity: 0.9
        }
    }
}
