#include "customwebview.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtGui/qwindow.h>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  // Our custom webviews for each platform, we're using native webviews instead
  // of bundling full Chromium thru QtWebEngine

  CustomWebView *customWebView = new CustomWebView();

  engine.rootContext()->setContextProperty("webViewWindow", customWebView);

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("NativeWebView", "Main");

  return app.exec();
}
