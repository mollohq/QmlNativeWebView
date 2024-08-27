cmake_minimum_required(VERSION 3.16)

# Setup VCPKG script with CMake (note: should be placed before project() call)
list(APPEND VCPKG_FEATURE_FLAGS "versions")
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")

message(" [INFO] VCPKG CMAKE_TOOLCHAIN_FILE = ${CMAKE_TOOLCHAIN_FILE}")
message(" [INFO] VCPKG TRIPLET = ${VCPKG_TARGET_TRIPLET}")

project(NativeWebView VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED OFF)

if(WIN32)
  set(VCPKG_TARGET_TRIPLET "x64-windows" CACHE STRING "")
endif()


find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick QuickWidgets)

qt_standard_project_setup(REQUIRES 6.5)

# WebView2 setup
if(MSVC)
    find_package(unofficial-webview2 CONFIG REQUIRED)
endif()

set(PROJECT_SOURCES
        main.cpp
        customwebview.h

)

# Platform-specific implementations of Custom Web View.
# On macOS we use the OS-provided WebKit (Safari engine)
# On Windows we use WebView2, which is the Edge engine and already provided by the OS
if (APPLE)
    set(PROJECT_SOURCES ${PROJECT_SOURCES} customwebview_mac.mm)
elseif (WIN32 AND MSVC)
  set(PROJECT_SOURCES ${PROJECT_SOURCES} customwebview_win.cpp)
elseif (UNIX AND ${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(PROJECT_SOURCES ${PROJECT_SOURCES} customwebview_nix.cpp)
endif ()

qt_add_executable(NativeWebView
    ${PROJECT_SOURCES}
)

qt_add_qml_module(NativeWebView
    URI NativeWebView
    VERSION 1.0
    QML_FILES
        Main.qml
        NativeWebView.qml
        SOURCES
)

target_link_libraries(NativeWebView PRIVATE
    Qt::Core
    Qt::Quick
)

if (APPLE)
    target_link_libraries(${PROJECT_NAME}
      PUBLIC
      "-framework WebKit"
     )
elseif(WIN32)
  target_link_libraries(${PROJECT_NAME} PRIVATE user32.lib gdi32.lib)
  target_link_libraries(${PROJECT_NAME} PRIVATE unofficial::webview2::webview2)
endif()


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

