import QtQuick
import QtQuick.Controls

import com.mollohq.examples

Window {
    height: 600
    title: qsTr("WKWebView Example")
    visible: true
    width: 800

    Rectangle {
        anchors.fill: parent
        color: "lightgray"

        Rectangle {
            anchors.centerIn: parent
            border.color: "black"
            border.width: 2
            color: "white"
            height: 400
            width: 600

            WebViewItem {
                id: webView

                anchors.fill: parent
                // Remove the margins
                url: "https://www.svt.se/"

                onHeightChanged: console.log("WebViewItem height:", height)

                // Add this to check the actual size of the WebViewItem
                onWidthChanged: console.log("WebViewItem width:", width)

                // Rectangle {
                //     anchors.fill: parent
                //     color: "red"
                //     opacity: 0.3
                // }
            }
        }
    }
    TextField {
        id: urlInput

        anchors.left: parent.left
        anchors.margins: 10
        anchors.right: loadButton.left
        anchors.top: parent.top
        placeholderText: "Enter URL"
    }
    Button {
        id: loadButton

        anchors.margins: 10
        anchors.right: parent.right
        anchors.top: parent.top
        text: "Load"

        onClicked: webView.loadUrl(urlInput.text)
    }
}
