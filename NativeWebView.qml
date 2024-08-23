import QtQuick

WindowContainer {
    property url url

    window: webViewWindow

    Component.onCompleted: {
        console.log("WindowContainer - component completed");
    }
    onUrlChanged: {
        webViewManager.url = url;
    }
}
