#include "WebViewItem.h"
#include <QQuickItem>
#include <QQuickWindow>
#include <QSGSimpleRectNode>
#include <QTimer>
#import <WebKit/WebKit.h>

class WebViewItem::WebViewImplementation {
public:
  WKWebView *webView;
  QString url;
  NSView *containerView;
  QPointer<QQuickWindow> window;
  bool isInitialized;
  QPointF lastPos;
  QQuickItem *flickable;
  QTimer *updateTimer;
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
    : QQuickItem(parent), d(new WebViewImplementation) {
  setFlag(ItemHasContents, true);
  setAcceptedMouseButtons(Qt::AllButtons);
  setAcceptHoverEvents(true);

  d->isInitialized = false;
  d->webView = nil;
  d->containerView = nil;
  d->flickable = nullptr;

  d->updateTimer = new QTimer(this);
  d->updateTimer->setInterval(16); // ~60 fps
  d->updateTimer->setSingleShot(false);
  connect(d->updateTimer, &QTimer::timeout, this,
          &WebViewItem::updateWebViewGeometry);

  connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *window) {
    if (d->window)
      disconnect(d->window, &QQuickWindow::beforeRendering, this,
                 &WebViewItem::updateWebViewGeometry);

    d->window = window;

    if (window) {
      initializeWebView();
      connect(window, &QQuickWindow::beforeRendering, this,
              &WebViewItem::updateWebViewGeometry, Qt::DirectConnection);
    } else if (d->containerView) {
      [d->containerView removeFromSuperview];
    }
  });

  connect(this, &QQuickItem::xChanged, this,
          &WebViewItem::updateWebViewGeometry);
  connect(this, &QQuickItem::yChanged, this,
          &WebViewItem::updateWebViewGeometry);
}

WebViewItem::~WebViewItem() {
  if (d->containerView) {
    [d->containerView removeFromSuperview];
  }
  d->updateTimer->stop();
}

void WebViewItem::initializeWebView() {
  if (d->isInitialized)
    return;

  d->containerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];

  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
  d->webView = [[WKWebView alloc] initWithFrame:[d->containerView bounds]
                                  configuration:configuration];
  [d->containerView addSubview:d->webView];

  WebViewDelegate *delegate = [[WebViewDelegate alloc] init];
  delegate.item = this;
  d->webView.navigationDelegate = delegate;

  NSView *view =
      (__bridge NSView *)reinterpret_cast<void *>(d->window->winId());
  [view addSubview:d->containerView];

  d->isInitialized = true;

  if (!d->url.isEmpty()) {
    loadUrl(d->url);
  }

  updateWebViewGeometry();
  connectToScrollView();
}

QQuickItem *WebViewItem::findScrollView() {
  QQuickItem *parent = parentItem();
  while (parent) {
    if (QString(parent->metaObject()->className()) == "QQuickFlickable") {
      return parent;
    }
    parent = parent->parentItem();
  }
  return nullptr;
}

void WebViewItem::connectToScrollView() {
  d->flickable = findScrollView();
  if (d->flickable) {
    connect(d->flickable, SIGNAL(contentYChanged()), this,
            SLOT(updateWebViewGeometry()));
    d->updateTimer->start();
  }
}

QString WebViewItem::url() const { return d->url; }

void WebViewItem::setUrl(const QString &url) {
  if (d->url != url) {
    d->url = url;
    if (d->isInitialized) {
      loadUrl(url);
    }
    emit urlChanged();
  }
}

void WebViewItem::loadUrl(const QString &url) {
  if (d->isInitialized && d->webView) {
    NSURL *nsUrl = [NSURL URLWithString:url.toNSString()];
    [d->webView loadRequest:[NSURLRequest requestWithURL:nsUrl]];
    qDebug() << "Loading URL:" << url;
  } else {
    d->url = url; // Store the URL for later loading
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

  // Adjust for scroll position
  if (d->flickable) {
    qreal contentY = d->flickable->property("contentY").toReal();
    scenePos.setY(scenePos.y() - contentY);
  }

  NSView *view =
      (__bridge NSView *)reinterpret_cast<void *>(d->window->winId());
  NSRect bounds = [view bounds];

  CGFloat flippedY = bounds.size.height - scenePos.y() - size.height();

  NSRect newFrame =
      NSMakeRect(scenePos.x(), flippedY, size.width(), size.height());

  if (!NSEqualRects([d->containerView frame], newFrame) ||
      scenePos != d->lastPos) {
    [d->containerView setFrame:newFrame];
    [d->webView setFrame:[d->containerView bounds]];
    d->lastPos = scenePos;
  }

  [d->containerView setHidden:!isVisible()];

  qDebug() << "Updating geometry: " << scenePos << " Size: " << size
           << " ContentY: "
           << (d->flickable ? d->flickable->property("contentY").toReal() : 0);
}

QSGNode *WebViewItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
  if (!oldNode) {
    oldNode = new QSGSimpleRectNode(boundingRect(), Qt::transparent);
  }

  QSGSimpleRectNode *rectNode = static_cast<QSGSimpleRectNode *>(oldNode);
  rectNode->setRect(boundingRect());

  return rectNode;
}

void WebViewItem::componentComplete() {
  QQuickItem::componentComplete();
  initializeWebView();
}

void WebViewItem::itemChange(ItemChange change, const ItemChangeData &value) {
  QQuickItem::itemChange(change, value);
  if (change == ItemSceneChange && value.window) {
    connectToScrollView();
  }
}