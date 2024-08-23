import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import com.mollohq.examples

Window {
    height: 600
    title: qsTr("WKWebView ScrollView Example")
    visible: true
    width: 800

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            TextField {
                id: urlInput

                Layout.fillWidth: true
                placeholderText: "Enter URL"
                text: webView.url
            }
            Button {
                text: "Load"

                onClicked: webView.loadUrl(urlInput.text)
            }
        }
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true

            ColumnLayout {
                spacing: 20
                width: parent.width

                Rectangle {
                    Layout.fillWidth: true
                    color: "lightblue"
                    height: 100

                    Text {
                        anchors.centerIn: parent
                        text: "Item above WebView"
                    }
                }
                WebViewItem {
                    id: webView

                    Layout.fillWidth: true
                    height: 400
                    url: "https://www.svt.se"

                    onUrlChanged: urlInput.text = this.url
                }
                Rectangle {
                    Layout.fillWidth: true
                    color: "lightgreen"
                    height: 100

                    Text {
                        anchors.centerIn: parent
                        text: "Item below WebView"
                    }
                }
                Repeater {
                    model: 5

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        color: Qt.rgba(Math.random(), Math.random(), Math.random(), 1)
                        height: 100

                        Text {
                            anchors.centerIn: parent
                            text: "Scrollable Item " + (index + 1)
                        }
                    }
                }
            }
        }
    }
}
