cmake_minimum_required(VERSION 3.16)

project(NativeWebView VERSION 0.1 LANGUAGES CXX)

# set(CMAKE_CXX_STANDARD 17)
# set(CMAKE_CXX_STANDARD_REQUIRED ON)

# find_package(Qt6 REQUIRED COMPONENTS Core Quick)

# set(PROJECT_SOURCES
#         main.cpp
#         test.h
#         test.cpp
#         #WebViewItem.h
#         #WebViewItem.mm
#         Main.qml
# )

# qt_add_executable(QmlWKWebViewExample
#     ${PROJECT_SOURCES}

# )

# target_link_libraries(QmlWKWebViewExample PRIVATE
#     Qt6::Core
#     Qt6::Quick
#     "-framework WebKit"
#     "-framework Foundation"
#     "-framework Cocoa"
# )

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickWidgets)

qt_standard_project_setup(REQUIRES 6.5)

set(PROJECT_SOURCES
        main.cpp
        customwebviewwindow.h
        customwebviewwindow.mm
)


qt_add_executable(NativeWebView
    ${PROJECT_SOURCES}
)

qt_add_qml_module(NativeWebView
    URI NativeWebView
    VERSION 1.0
    QML_FILES
        Main.qml
        NativeWebView.qml
)

target_link_libraries(NativeWebView PRIVATE
    Qt6::Quick
    Qt6::QuickWidgets
    "-framework WebKit"
)


# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(NativeWebView PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.NativeWebView
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)



include(GNUInstallDirs)
install(TARGETS NativeWebView
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

