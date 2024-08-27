#include "customwebview.h"

#include "WebView2.h"
#include <QGuiApplication>
#include <WebView2EnvironmentOptions.h>

using namespace Microsoft::WRL;

CustomWebView::CustomWebView(QWindow *parent)
    : QWindow(parent), m_isInitialized(false), m_pendingUrl(),
      m_childWindow(nullptr), m_childWindowHandle(nullptr) {
  // Set up a custom User Data Folder
  QString appDataLocation =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  m_userDataFolder = QDir(appDataLocation).filePath("WebView2UserData");
  QDir().mkpath(m_userDataFolder);

  setFlags(Qt::FramelessWindowHint);
}

CustomWebView::~CustomWebView() { cleanup(); }

void CustomWebView::reset() {
  cleanup();
  initialize();
}

void CustomWebView::initialize() {
  if (!m_isInitialized) {
    // Create a child window
    m_childWindowHandle = ::CreateWindowEx(
        0, L"Static", L"", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0,
        reinterpret_cast<HWND>(winId()), NULL, nullptr, nullptr);

    if (m_childWindowHandle) {
      // Create a QWindow from the child window handle
      m_childWindow =
          QWindow::fromWinId(reinterpret_cast<WId>(m_childWindowHandle));
      if (m_childWindow) {
        // Set the child window as a child of this CustomWebView
        m_childWindow->setParent(this);
        m_childWindow->setFlags(Qt::WindowType::Widget);

        initializeWebView();
      }
    }
  }
}

void CustomWebView::cleanup() {
  if (m_webView) {
    m_webView->remove_NavigationStarting(m_navigationStartingToken);
  }
  if (m_webViewController) {
    m_webViewController->Close();
    m_webViewController = nullptr;
  }
  m_webView = nullptr;
  if (m_childWindow) {
    delete m_childWindow;
    m_childWindow = nullptr;
  }
  if (m_childWindowHandle) {
    ::DestroyWindow(m_childWindowHandle);
    m_childWindowHandle = nullptr;
  }

  m_isInitialized = false;
  emit isInitializedChanged();
}

void CustomWebView::initializeWebView() {
  // Create WebView2 Environment Options
  auto options = Microsoft::WRL::Make<CoreWebView2EnvironmentOptions>();
  options->put_AllowSingleSignOnUsingOSPrimaryAccount(FALSE);

  // Convert QString to LPCWSTR
  std::wstring userDataFolderW = m_userDataFolder.toStdWString();
  LPCWSTR userDataFolderLPCW = userDataFolderW.c_str();

  HRESULT hr = CreateCoreWebView2EnvironmentWithOptions(
      nullptr, userDataFolderLPCW, options.Get(),
      Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
          [this](HRESULT result, ICoreWebView2Environment *env) -> HRESULT {
            if (SUCCEEDED(result)) {
              env->CreateCoreWebView2Controller(
                  m_childWindowHandle,
                  Callback<
                      ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                      [this](HRESULT result,
                             ICoreWebView2Controller *controller) -> HRESULT {
                        if (SUCCEEDED(result)) {
                          m_webViewController = controller;
                          m_webViewController->AddRef();

                          m_webViewController->get_CoreWebView2(&m_webView);
                          m_webView->AddRef();

                          setupNavigationEventHandler();

// Hide context menu if not in debug mode
#ifndef DEBUG
                          ICoreWebView2Settings *settings;
                          m_webView->get_Settings(&settings);
                          settings->put_AreDefaultContextMenusEnabled(FALSE);
#endif

                          m_webViewController->put_IsVisible(TRUE);
                          m_isInitialized = true;
                          emit isInitializedChanged();

                          // Load the pending URL if it exists
                          if (!m_pendingUrl.isEmpty()) {
                            setUrl(m_pendingUrl);
                            m_pendingUrl.clear();
                          }
                        }
                        return S_OK;
                      })
                      .Get());
            }
            return S_OK;
          })
          .Get());

  Q_UNUSED(hr);
}

void CustomWebView::setupNavigationEventHandler() {
  if (m_webView) {
    m_webView->add_NavigationStarting(
        Callback<ICoreWebView2NavigationStartingEventHandler>(
            [this](ICoreWebView2 *sender,
                   ICoreWebView2NavigationStartingEventArgs *args) -> HRESULT {
              Q_UNUSED(sender);
              LPWSTR url;
              args->get_Uri(&url);
              QString qUrl = QString::fromWCharArray(url);
              CoTaskMemFree(url);

              QUrl newUrl(qUrl);
              if (m_url != newUrl) {
                m_url = newUrl;
                emit urlChanged(m_url);
              }
              return S_OK;
            })
            .Get(),
        &m_navigationStartingToken);
  }
}

void CustomWebView::setUrl(const QUrl &url) {
  if (m_isInitialized && m_webView) {
    m_webView->Navigate(reinterpret_cast<LPCWSTR>(url.toString().utf16()));
    m_url = url;
    emit urlChanged(m_url);
  } else {
    m_pendingUrl = url;
  }
}

void CustomWebView::updateWebViewBounds(int width, int height) {
  if (m_webViewController && m_webView) {
    RECT bounds;
    bounds.left = 0;
    bounds.top = 0;
    bounds.right = width * devicePixelRatio();
    bounds.bottom = height * devicePixelRatio();
    m_webViewController->put_Bounds(bounds);

    // Update the child window size as well
    if (m_childWindow) {
      m_childWindow->setGeometry(0, 0, width, height);
    }

    qDebug() << __FUNCTION__ << "new bounds, height: " << height
             << ", width: " << width
             << ", device pixel ratio: " << devicePixelRatio();
  }
}

void CustomWebView::resizeEvent(QResizeEvent *event) {
  QWindow::resizeEvent(event);
  updateWebViewBounds(event->size().width(), event->size().height());
}
