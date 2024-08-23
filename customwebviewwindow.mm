#include "customwebviewwindow.h"
#include "QtCore/qurl.h"

#include <QDebug>
#include <QWindow>

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <WebKit/WKWebView.h>
#include <WebKit/WebKit.h>

// -------------------------------------------------------------------------

@interface QtWKWebViewDelegate : NSObject <WKNavigationDelegate> {
  CustomWebviewWindow *qWebView;
}
- (QtWKWebViewDelegate *)initWithWebView:(CustomWebviewWindow *)webViewPrivate;

// protocol:
- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation;
@end

@implementation QtWKWebViewDelegate
- (QtWKWebViewDelegate *)initWithWebView:(CustomWebviewWindow *)webViewPrivate {
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

CustomWebviewWindow::CustomWebviewWindow(QObject *parent) : QObject(parent) {

  try {
    auto _webView = [WKWebView new];
#ifdef DEBUG
    [_webView.configuration.preferences setValue:@YES
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
    wkWebView = _webView;

    wkWebView.navigationDelegate =
        [[QtWKWebViewDelegate alloc] initWithWebView:this];

  } catch (const std::exception &e) {
    qDebug() << __FUNCTION__ << e.what();
  }
}

CustomWebviewWindow::~CustomWebviewWindow() {
  if (wkWebView) {
    [wkWebView stopLoading];
    [wkWebView.navigationDelegate release];
    wkWebView.navigationDelegate = nil;
    [wkWebView release];
  }
}

QWindow *CustomWebviewWindow::webWindow() {
  if (!wkWebView) {
    return nullptr;
  }

  // Get the window handle
  WId winId = WId(wkWebView);

  // Create a QWindow from the native window handle
  QWindow *qWindow = QWindow::fromWinId(winId);

  return qWindow;
}

QUrl CustomWebviewWindow::url() const {
  Q_ASSERT(wkWebView);
  return QUrl::fromNSURL(wkWebView.URL);
}

void CustomWebviewWindow::setUrl(const QUrl &url) {
  if (url.isValid()) {
    [wkWebView loadRequest:[NSURLRequest requestWithURL:url.toNSURL()]];
  }
}