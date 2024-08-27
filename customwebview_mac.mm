// customwebview.mm
#include "customwebview.h"

#ifdef Q_OS_MAC
#include <QGuiApplication>
#include <QWindow>
#import <WebKit/WebKit.h>

@interface CustomWebViewDelegate : NSObject <WKNavigationDelegate> {
  CustomWebView *qWebView;
}
- (CustomWebViewDelegate *)initWithWebView:(CustomWebView *)webViewPrivate;
- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation;
@end

@implementation CustomWebViewDelegate

- (CustomWebViewDelegate *)initWithWebView:(CustomWebView *)webViewPrivate {
  if ((self = [super init])) {
    Q_ASSERT(webViewPrivate);
    qWebView = webViewPrivate;
  }
  return self;
}

- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation {
  Q_UNUSED(webView);
  if (qWebView->wkNavigation != navigation)
    return;
  Q_EMIT qWebView->urlChanged(qWebView->url());
}

@end

CustomWebView::CustomWebView(QWindow *parent)
    : QWindow(parent), m_isInitialized(false), m_childWindow(nullptr),
      _wkWebView(nil) {
  setFlags(Qt::FramelessWindowHint);
}

CustomWebView::~CustomWebView() { cleanup(); }

void CustomWebView::initialize() {
  if (!m_isInitialized) {
    try {
      WKWebView *webView =
          [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, width(), height())];
#ifdef DEBUG
      [webView.configuration.preferences setValue:@YES
                                           forKey:@"developerExtrasEnabled"];
#endif
      WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
      NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
      NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
      [dataStore removeDataOfTypes:websiteDataTypes
                     modifiedSince:dateFrom
                 completionHandler:^{
                   NSLog(@"All website data has been cleared");
                 }];

      _wkWebView = webView;
      _wkWebView.navigationDelegate =
          [[CustomWebViewDelegate alloc] initWithWebView:this];

      // Create a child QWindow from the WKWebView
      m_childWindow = QWindow::fromWinId(WId(_wkWebView));
      if (m_childWindow) {
        m_childWindow->setParent(this);
        m_childWindow->setFlags(Qt::WindowType::Widget);
      }

      m_isInitialized = true;
      Q_EMIT isInitializedChanged();

      // Load the pending URL if it exists
      if (!m_pendingUrl.isEmpty()) {
        setUrl(m_pendingUrl);
        m_pendingUrl.clear();
      }

    } catch (const std::exception &e) {
      qDebug() << __FUNCTION__ << e.what();
    }
  }
}

void CustomWebView::cleanup() {
  if (_wkWebView) {
    [_wkWebView removeFromSuperview];
    [_wkWebView release];
    _wkWebView = nil;
  }

  if (m_childWindow) {
    m_childWindow->setParent(nullptr);
    delete m_childWindow;
    m_childWindow = nullptr;
  }

  m_isInitialized = false;
  Q_EMIT isInitializedChanged();
}

void CustomWebView::reset() {
  cleanup();
  initialize();
}

void CustomWebView::setUrl(const QUrl &url) {
  if (m_isInitialized && _wkWebView) {
    NSURL *nsurl = url.toNSURL();
    [_wkWebView loadRequest:[NSURLRequest requestWithURL:nsurl]];
    qDebug() << __FUNCTION__ << "Navigated to: " << url;
  } else {
    m_pendingUrl = url;
  }
}

void CustomWebView::updateWebViewBounds(int width, int height) {
  if (_wkWebView) {
    [_wkWebView setFrame:NSMakeRect(0, 0, width, height)];
  }

  if (m_childWindow) {
    m_childWindow->setGeometry(0, 0, width, height);
  }
}

void CustomWebView::resizeEvent(QResizeEvent *event) {
  QWindow::resizeEvent(event);
  updateWebViewBounds(event->size().width(), event->size().height());
}

#endif // Q_OS_MAC
