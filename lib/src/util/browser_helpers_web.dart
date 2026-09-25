import 'package:web/web.dart' as web;

/// Whether the app runs in a WebKit-based browser: Safari on macOS, or any
/// browser on iOS/iPadOS (they are all forced to use WebKit).
///
/// Detection ported from the workaround recommended by the Firebase team in
/// https://github.com/firebase/firebase-js-sdk/issues/9789.
bool get isWebKitBrowser {
  final navigator = web.window.navigator;
  final userAgent = navigator.userAgent;

  // iPadOS 13+ reports 'MacIntel' as platform but, unlike Macs with
  // Apple Silicon, exposes multiple touch points.
  final isIOS =
      RegExp(r'iPad|iPhone|iPod').hasMatch(userAgent) ||
      (navigator.platform == 'MacIntel' && navigator.maxTouchPoints > 1);

  // Safari on macOS: 'safari' in the user agent without the tokens other
  // browsers (Chrome, Firefox, iOS variants) add.
  final isMacSafari = RegExp(
    r'^((?!chrome|android|crios|fxios).)*safari',
    caseSensitive: false,
  ).hasMatch(userAgent);

  return isIOS || isMacSafari;
}
