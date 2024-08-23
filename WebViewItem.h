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

private:
  void updateWebViewGeometry();
  class Private;
  QScopedPointer<Private> d;
};

#endif // WEBVIEWITEM_H