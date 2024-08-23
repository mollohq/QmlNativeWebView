
#ifndef CUSTOMWEBVIEWWINDOW_H
#define CUSTOMWEBVIEWWINDOW_H

#include "QtCore/qurl.h"
#include "QtGui/qwindowdefs.h"
#include <QObject>

#ifdef Q_OS_WIN
namespace webview {
namespace detail {
class win32_edge_engine;
}
} // namespace webview
#endif

Q_FORWARD_DECLARE_OBJC_CLASS(WKWebView);
Q_FORWARD_DECLARE_OBJC_CLASS(WKNavigation);

class CustomWebviewWindow : public QObject {
  Q_OBJECT

  Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)

public:
  explicit CustomWebviewWindow(QObject *parent = nullptr);
  ~CustomWebviewWindow();

  QWindow *webWindow();
  WId widget();

  QUrl url() const;
  Q_INVOKABLE void setUrl(const QUrl &url);

signals:
  void urlChanged(const QUrl &url);

  // ------------------------------

private:
#ifdef Q_OS_WIN
  webview::detail::win32_edge_engine *_webView;
#endif

public:
  WKWebView *wkWebView;
  WKNavigation *wkNavigation;
};

#endif // CUSTOMWEBVIEWWINDOW_H
