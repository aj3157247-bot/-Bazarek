package com.bazarek.app;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.Gravity;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.GeolocationPermissions;
import android.webkit.RenderProcessGoneDetail;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;

import java.io.File;
import java.io.IOException;
import java.util.Locale;

public class MainActivity extends Activity {
    private static final String WEB_ORIGIN = "https://bazarek-web.onrender.com";
    private static final String WEB_URL = WEB_ORIGIN + "/?bazarek_app=1&shell=android";
    private static final int FILE_CHOOSER_REQUEST = 4101;
    private static final int CAMERA_PERMISSION_REQUEST = 4102;
    private static final int LOCATION_PERMISSION_REQUEST = 4103;

    private WebView webView;
    private ValueCallback<Uri[]> fileCallback;
    private Uri cameraOutputUri;
    private View errorView;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.WHITE);
        getWindow().setNavigationBarColor(Color.WHITE);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);

        buildUi();
        configureWebView();
        loadBazarek();
    }

    private void buildUi() {
        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.WHITE);

        webView = new WebView(this);
        webView.setBackgroundColor(Color.WHITE);
        root.addView(webView, new FrameLayout.LayoutParams(-1, -1));

        progressBar = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        progressBar.setMax(100);
        progressBar.setProgress(0);
        FrameLayout.LayoutParams progressParams = new FrameLayout.LayoutParams(-1, dp(3));
        progressParams.gravity = Gravity.TOP;
        root.addView(progressBar, progressParams);

        errorView = createErrorView();
        errorView.setVisibility(View.GONE);
        root.addView(errorView, new FrameLayout.LayoutParams(-1, -1));

        setContentView(root);
    }

    private View createErrorView() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setGravity(Gravity.CENTER);
        box.setPadding(dp(28), dp(28), dp(28), dp(28));
        box.setBackgroundColor(Color.WHITE);

        TextView title = new TextView(this);
        title.setText("اتصال به بازارک برقرار نشد");
        title.setTextColor(Color.rgb(30, 30, 30));
        title.setTextSize(20);
        title.setGravity(Gravity.CENTER);

        TextView message = new TextView(this);
        message.setText("لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.");
        message.setTextColor(Color.DKGRAY);
        message.setTextSize(16);
        message.setGravity(Gravity.CENTER);
        message.setPadding(0, dp(12), 0, dp(18));

        Button retry = new Button(this);
        retry.setText("تلاش دوباره");
        retry.setOnClickListener(v -> loadBazarek());

        box.addView(title);
        box.addView(message);
        box.addView(retry, new LinearLayout.LayoutParams(-2, -2));
        return box;
    }

    private void configureWebView() {
        WebView.setWebContentsDebuggingEnabled(false);
        webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        webView.setOverScrollMode(View.OVER_SCROLL_NEVER);
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
        webView.setFocusable(true);
        webView.setFocusableInTouchMode(true);

        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setJavaScriptCanOpenWindowsAutomatically(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        s.setLoadsImagesAutomatically(true);
        s.setBlockNetworkImage(false);
        s.setBlockNetworkLoads(false);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(false);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);
        s.setCacheMode(WebSettings.LOAD_DEFAULT);
        s.setTextZoom(100);
        s.setUserAgentString(s.getUserAgentString() + " BazarekApp/1.4");

        CookieManager cookies = CookieManager.getInstance();
        cookies.setAcceptCookie(true);
        cookies.setAcceptThirdPartyCookies(webView, true);
        cookies.flush();

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return handleUrl(request.getUrl());
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return handleUrl(Uri.parse(url));
            }

            @Override
            public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {
                progressBar.setVisibility(View.VISIBLE);
                progressBar.setProgress(5);
                hideError();
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                progressBar.setProgress(100);
                progressBar.setVisibility(View.GONE);
                hideError();
            }

            @Override
            public void onProgressChanged(WebView view, int progress) {
                progressBar.setProgress(progress);
                if (progress >= 100) progressBar.setVisibility(View.GONE);
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                if (request.isForMainFrame()) showError();
            }

            @Override
            public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse response) {
                if (request.isForMainFrame() && response != null && response.getStatusCode() >= 400) showError();
            }

            @Override
            public boolean onRenderProcessGone(WebView view, RenderProcessGoneDetail detail) {
                showError();
                return true;
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (fileCallback != null) fileCallback.onReceiveValue(null);
                fileCallback = callback;
                if (params.isCaptureEnabled() && wantsImage(params)) openCamera();
                else openFilePicker(params);
                return true;
            }

            @Override
            public void onPermissionRequest(android.webkit.PermissionRequest request) {
                request.grant(request.getResources());
            }

            @Override
            public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
                if (ContextCompat.checkSelfPermission(MainActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                        || ContextCompat.checkSelfPermission(MainActivity.this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    callback.invoke(origin, true, false);
                } else {
                    callback.invoke(origin, false, false);
                }
            }
        });
    }

    private void loadBazarek() {
        hideError();
        progressBar.setVisibility(View.VISIBLE);
        progressBar.setProgress(5);
        webView.setVisibility(View.VISIBLE);
        webView.loadUrl(WEB_URL);
    }

    private boolean wantsImage(WebChromeClient.FileChooserParams params) {
        String[] types = params.getAcceptTypes();
        if (types == null || types.length == 0) return true;
        for (String type : types) {
            if (type != null && (type.equalsIgnoreCase("image/*") || type.toLowerCase(Locale.US).startsWith("image/"))) return true;
        }
        return false;
    }

    private void openFilePicker(WebChromeClient.FileChooserParams params) {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("image/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, params.getMode() == WebChromeClient.FileChooserParams.MODE_OPEN_MULTIPLE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        try {
            startActivityForResult(intent, FILE_CHOOSER_REQUEST);
        } catch (ActivityNotFoundException e) {
            finishFileSelection(null);
        }
    }

    private void openCamera() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, CAMERA_PERMISSION_REQUEST);
            return;
        }
        try {
            File dir = new File(getCacheDir(), "camera");
            if (!dir.exists() && !dir.mkdirs()) throw new IOException("camera directory");
            File file = File.createTempFile("bazarek_", ".jpg", dir);
            cameraOutputUri = FileProvider.getUriForFile(this, "com.bazarek.app.fileprovider", file);
            Intent camera = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            camera.putExtra(MediaStore.EXTRA_OUTPUT, cameraOutputUri);
            camera.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
            startActivityForResult(camera, FILE_CHOOSER_REQUEST);
        } catch (IOException | ActivityNotFoundException e) {
            finishFileSelection(null);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == CAMERA_PERMISSION_REQUEST) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) openCamera();
            else finishFileSelection(null);
        } else if (requestCode == LOCATION_PERMISSION_REQUEST) {
            // Geolocation is optional; the website can continue without it.
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != FILE_CHOOSER_REQUEST) return;
        if (resultCode != RESULT_OK) {
            finishFileSelection(null);
            return;
        }
        if (cameraOutputUri != null) {
            Uri result = cameraOutputUri;
            cameraOutputUri = null;
            finishFileSelection(new Uri[]{result});
            return;
        }
        if (data == null) {
            finishFileSelection(null);
            return;
        }
        if (data.getClipData() != null) {
            int count = data.getClipData().getItemCount();
            Uri[] results = new Uri[count];
            for (int i = 0; i < count; i++) {
                results[i] = data.getClipData().getItemAt(i).getUri();
                try { getContentResolver().takePersistableUriPermission(results[i], Intent.FLAG_GRANT_READ_URI_PERMISSION); } catch (Exception ignored) {}
            }
            finishFileSelection(results);
        } else if (data.getData() != null) {
            Uri uri = data.getData();
            try { getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION); } catch (Exception ignored) {}
            finishFileSelection(new Uri[]{uri});
        } else {
            finishFileSelection(null);
        }
    }

    private void finishFileSelection(Uri[] results) {
        if (fileCallback != null) {
            fileCallback.onReceiveValue(results);
            fileCallback = null;
        }
        cameraOutputUri = null;
    }

    private boolean handleUrl(Uri uri) {
        if (uri == null) return true;
        String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.US);
        String host = uri.getHost() == null ? "" : uri.getHost().toLowerCase(Locale.US);

        if ((scheme.equals("https") || scheme.equals("http"))
                && (host.equals("bazarek-web.onrender.com") || host.endsWith(".bazarek-web.onrender.com"))) {
            return false;
        }

        if (scheme.equals("tel") || scheme.equals("mailto") || scheme.equals("sms")
                || scheme.equals("whatsapp") || scheme.equals("geo")) {
            try { startActivity(new Intent(Intent.ACTION_VIEW, uri)); } catch (ActivityNotFoundException ignored) {}
            return true;
        }

        if (scheme.equals("http") || scheme.equals("https")) {
            try { startActivity(new Intent(Intent.ACTION_VIEW, uri)); } catch (ActivityNotFoundException ignored) {}
            return true;
        }
        return true;
    }

    private void showError() {
        progressBar.setVisibility(View.GONE);
        webView.setVisibility(View.GONE);
        errorView.setVisibility(View.VISIBLE);
    }

    private void hideError() {
        errorView.setVisibility(View.GONE);
        webView.setVisibility(View.VISIBLE);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }
}
