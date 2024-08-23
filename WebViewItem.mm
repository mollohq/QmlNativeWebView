#include "WebViewItem.h"
#include <QQuickWindow>
#include <QSGSimpleRectNode>
#import <WebKit/WebKit.h>

class WebViewItem::Private {
public:
  WKWebView *webView;
  QString url;
  NSView *containerView;
  QPointer<QQuickWindow> window;
};

@interface WebViewDelegate : NSObject <WKNavigationDelegate>
@property(nonatomic, assign) WebViewItem *item;
@end

@implementation WebViewDelegate

- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation {
  if (self.item) {
    self.item->setUrl(QString::fromNSString(webView.URL.absoluteString));
  }
  NSLog(@"Web page finished loading: %@", webView.URL.absoluteString);
}

@end

WebViewItem::WebViewItem(QQuickItem *parent)
    : QQuickItem(parent), d(new Private) {
  setFlag(ItemHasContents, true);
  setAcceptedMouseButtons(Qt::AllButtons);
  setAcceptHoverEvents(true);

  d->containerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];

  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
  d->webView = [[WKWebView alloc] initWithFrame:[d->containerView bounds]
                                  configuration:configuration];
  [d->containerView addSubview:d->webView];

  WebViewDelegate *delegate = [[WebViewDelegate alloc] init];
  delegate.item = this;
  d->webView.navigationDelegate = delegate;

  connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *window) {
    if (d->window)
      disconnect(d->window, &QQuickWindow::beforeRendering, this,
                 &WebViewItem::updateWebViewGeometry);

    d->window = window;

    if (window) {
      NSView *view =
          (__bridge NSView *)reinterpret_cast<void *>(window->winId());
      [view addSubview:d->containerView];
      connect(window, &QQuickWindow::beforeRendering, this,
              &WebViewItem::updateWebViewGeometry, Qt::DirectConnection);
    } else if (d->containerView.superview) {
      [d->containerView removeFromSuperview];
    }
  });

  connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *window) {
    if (d->window)
      disconnect(d->window, &QQuickWindow::beforeRendering, this,
                 &WebViewItem::updateWebViewGeometry);

    d->window = window;

    if (window) {
      NSView *view =
          (__bridge NSView *)reinterpret_cast<void *>(window->winId());
      [view addSubview:d->containerView];
      connect(window, &QQuickWindow::beforeRendering, this,
              &WebViewItem::updateWebViewGeometry, Qt::DirectConnection);
      // Add this line to update geometry when the window is resized
      connect(window, &QQuickWindow::widthChanged, this,
              &WebViewItem::updateWebViewGeometry);
      connect(window, &QQuickWindow::heightChanged, this,
              &WebViewItem::updateWebViewGeometry);
    } else if (d->containerView.superview) {
      [d->containerView removeFromSuperview];
    }
  });

  // Add these connections to update geometry when the item's position changes
  connect(this, &QQuickItem::xChanged, this,
          &WebViewItem::updateWebViewGeometry);
  connect(this, &QQuickItem::yChanged, this,
          &WebViewItem::updateWebViewGeometry);
}

WebViewItem::~WebViewItem() {
  if (d->containerView.superview) {
    [d->containerView removeFromSuperview];
  }
}

QString WebViewItem::url() const { return d->url; }

void WebViewItem::setUrl(const QString &url) {
  if (d->url != url) {
    d->url = url;
    emit urlChanged();
  }
}

void WebViewItem::loadUrl(const QString &url) {
  if (d->url != url) {
    d->url = url;
    NSURL *nsUrl = [NSURL URLWithString:url.toNSString()];
    [d->webView loadRequest:[NSURLRequest requestWithURL:nsUrl]];
    qDebug() << "Loading URL:" << url;
    emit urlChanged();
  }
}

void WebViewItem::geometryChange(const QRectF &newGeometry,
                                 const QRectF &oldGeometry) {
  QQuickItem::geometryChange(newGeometry, oldGeometry);
  updateWebViewGeometry();
}

void WebViewItem::updateWebViewGeometry() {
  if (!d->window || !d->containerView)
    return;

  QPointF scenePos = mapToScene(QPointF(0, 0));
  QSizeF size = boundingRect().size();

  NSView *view =
      (__bridge NSView *)reinterpret_cast<void *>(d->window->winId());
  NSRect bounds = [view bounds];

  // Calculate the position relative to the bottom-left corner of the window
  CGFloat flippedY = bounds.size.height - scenePos.y() - size.height();

  NSRect newFrame =
      NSMakeRect(scenePos.x(), flippedY, size.width(), size.height());

  if (!NSEqualRects([d->containerView frame], newFrame)) {
    [d->containerView setFrame:newFrame];
    [d->webView setFrame:[d->containerView bounds]];
  }

  [d->containerView setHidden:!isVisible()];
}

QSGNode *WebViewItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
  if (!oldNode) {
    oldNode = new QSGSimpleRectNode(boundingRect(), Qt::transparent);
  }

  QSGSimpleRectNode *rectNode = static_cast<QSGSimpleRectNode *>(oldNode);
  rectNode->setRect(boundingRect());

  return rectNode;
}
