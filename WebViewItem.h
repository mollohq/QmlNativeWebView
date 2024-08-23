#ifndef WEBVIEWITEM_H
#define WEBVIEWITEM_H

#include <QQuickItem>

class WebViewItem : public QQuickItem {
  Q_OBJECT
  Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)
  QML_ELEMENT

public:
  explicit WebViewItem(QQuickItem *parent = nullptr);
  ~WebViewItem();

  QString url() const;
  void setUrl(const QString &url);

  Q_INVOKABLE void loadUrl(const QString &url);

signals:
  void urlChanged();

protected:
  void geometryChange(const QRectF &newGeometry,
                      const QRectF &oldGeometry) override;
  QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;
  void componentComplete() override;
  void itemChange(ItemChange change, const ItemChangeData &value) override;

private slots:
  void updateWebViewGeometry();

private:
  void initializeWebView();
  void connectToScrollView();
  QQuickItem *findScrollView();
  class WebViewImplementation;
  QScopedPointer<WebViewImplementation> d;
};

#endif // WEBVIEWITEM_H