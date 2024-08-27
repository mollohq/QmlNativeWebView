# Custom WebView Qt/QML Component

A lightweight custom WebView component for Qt/QML applications that utilizes the native OS-bundled WebView to display web content. This approach significantly reduces the application size by avoiding the need to bundle the full QtWebEngine.

## Features

- Lightweight alternative to QtWebEngine
- Uses native OS WebView components
- Seamless integration with Qt/QML applications
- Supports Qt 6.7 and above
- Works on Windows (using WebView2 Edge engine) and macOS (using WebKit)
- No *nix support currently, since I don't use it, but contributions are welcome

## Why?

We needed to show web content in our application [Mollo](https://github.com/mollo), and developed this since we didn't want to bundle Chromium in our app just to show some web content. 

## Requirements

This project relies on WindowContainer, which was introduced in Qt 6.7. We use it to integrate foreign native windows (i.e., the WebView itself).

## Installation

To use Custom WebView Qt/QML Component in your project, you need to have Qt 6.7 or higher installed on your system.

### Prerequisites

- Qt 6.7+
- CMake 3.14+
- A C++17 compatible compiler

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/custom-webview-qt.git
   cd custom-webview-qt
   ```

2. Fetch submodules:
   ```
   git submodule update --init --recursive
   ```

3. Create a build directory:
   ```
   mkdir build && cd build
   ```

4. Configure the project with CMake:
   ```
   cmake ..
   ```

5. Build the project:
   ```
   cmake --build .
   ```

6. (Optional) Install the library:
   ```
   sudo cmake --install .
   ```

## Usage

To use the Custom WebView component in your application:

1. In your main.cpp, add the following:

```cpp
#include <CustomWebView>

// ...

CustomWebView *customWebView = new CustomWebView();
engine.rootContext()->setContextProperty("webViewWindow", customWebView);
```

2. Then use the provided NativeWebView.qml in your QML as any other QML component:

```qml
import QtQuick
import QtQuick.Window

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Custom WebView Example")

    NativeWebView {
        anchors.fill: parent
        url: "https://www.example.com"
    }
}
```

For more detailed usage instructions and API documentation, please refer to the [Wiki](https://github.com/yourusername/custom-webview-qt/wiki).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request, especially for Linux support.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
