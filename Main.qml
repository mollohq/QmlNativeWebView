import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    height: 780
    title: qsTr("Custom WebView Example")
    visible: true
    width: 1024

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

                onAccepted: webView.url = urlInput.text
            }
            Button {
                text: "Load"

                onClicked: webView.url = urlInput.text
            }
        }

        // You could just use NativeWebView {} anywhere here, but i wanted to test the integration
        // in a more complex app, like scrolling the view etc.
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
                Item {
                    Layout.fillWidth: true
                    height: 600

                    NativeWebView {
                        id: webView

                        anchors.fill: parent
                        url: "https://mollo.io"
                    }
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
