#include "customwebviewwindow.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtGui/qwindow.h>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  CustomWebviewWindow *customWebViewMgr = new CustomWebviewWindow();

  engine.rootContext()->setContextProperty("webViewWindow",
                                           customWebViewMgr->webWindow());
  engine.rootContext()->setContextProperty("webViewManager", customWebViewMgr);

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("NativeWebView", "Main");

  return app.exec();
}
