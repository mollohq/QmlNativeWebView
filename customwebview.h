#pragma once
#include <QtGui>
#include <QtQml>
#include <QtQuick>
#ifdef Q_OS_WIN
#include <windows.h>
#include <wrl.h>
class ICoreWebView2Controller;
class ICoreWebView2;
#elif defined(Q_OS_MAC)
Q_FORWARD_DECLARE_OBJC_CLASS(WKWebView);
Q_FORWARD_DECLARE_OBJC_CLASS(WKNavigation);
#endif

class CustomWebView : public QWindow {
  Q_OBJECT
  Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
  Q_PROPERTY(bool isInitialized READ isInitialized NOTIFY isInitializedChanged)

  public:
  explicit CustomWebView(QWindow *parent = nullptr);
  ~CustomWebView();

  bool isInitialized() const { return m_isInitialized; }
  QUrl url() const { return m_url; }

  Q_INVOKABLE void setUrl(const QUrl &url);
  Q_INVOKABLE void reset();

  signals:
  void isInitializedChanged();
  void urlChanged(const QUrl &url);

  public slots:
  void updateWebViewBounds(int width, int height);
  void cleanup();

  protected:
  void resizeEvent(QResizeEvent *event) override;

  private slots:
  void initialize();

  private:
  bool m_isInitialized;
  QUrl m_pendingUrl;
  QUrl m_url;
  QWindow *m_childWindow;

#ifdef Q_OS_WIN
  void setupNavigationEventHandler();
  void initializeWebView();
  Microsoft::WRL::ComPtr<ICoreWebView2Controller> m_webViewController;
  Microsoft::WRL::ComPtr<ICoreWebView2> m_webView;
  HWND m_childWindowHandle;

  QString m_userDataFolder;
  EventRegistrationToken m_navigationStartingToken;
#elif defined(Q_OS_MAC)
  WKWebView *_wkWebView;

  public:
  WKNavigation *wkNavigation;
#endif
};
