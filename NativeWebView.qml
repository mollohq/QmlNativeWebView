import QtQuick

WindowContainer {
    property url url

    window: webViewWindow

    Component.onCompleted: {
        console.log("WindowContainer - component completed");
        webViewWindow.reset();
    }

    Connections {
        target: webViewWindow
        function onIsInitializedChanged() {
            if (webViewWindow.isInitialized) {
                console.log("NativeWebView is properly initalized now...");
                webViewWindow.updateWebViewBounds(width, height);
            }
        }
    }

    onUrlChanged: {
        webViewWindow.url = url;
    }
}
