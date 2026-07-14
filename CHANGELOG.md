## 2.0.1
* Fixed the Google Pay button never rendering: the `google_pay_button_view` platform view is
  now registered by the main plugin (`FlittMobilePlugin`), so it is actually loaded by the
  engine. Previously the factory lived in a plugin class that was never registered.
* Fixed the Google Pay button rendering blank due to a race: the native button is now created
  only after the payment configuration has loaded.
* Fixed the native Google Pay button failing to compile: `GooglePayButtonFactory`'s
  constructor is now `public`, so `FlittMobilePlugin` can register the
  `google_pay_button_view` platform view across packages.
* Fixed the Google Pay button throwing "RenderAndroidView was given an infinite size" when
  placed in a `Column`/`ScrollView`: the platform view is now wrapped in a height-bounded
  `SizedBox` (honors an explicit `height`, else the standard 48dp Google Pay button height).
* Fixed the Google Pay button rendering as a thin/narrow strip. It now fills the host width by
  default (was `WRAP_CONTENT`, which clamped it to ~168dp and left-aligned it), and the native
  side converts the Dart logical-pixel (dp) `width`/`height` to physical pixels before applying
  them — previously e.g. `height: 48` was treated as 48px (~16dp on a 3x screen). The button is
  centered and filled to the full brand-guide height, with a 48dp minimum enforced Dart-side.
  See https://developers.google.com/pay/api/web/guides/brand-guidelines
* Kept the native Google Pay button (Google's `PayButton` via the `google_pay_button_view`
  platform view); deliberately did not migrate to the `pay` package, which would raise the
  Android floor to `minSdkVersion 23`. The plugin keeps `minSdkVersion 21` and declares the
  Google Pay libraries as `compileOnly`, so it imposes no Google-Pay-related floor. Note that
  `play-services-wallet:19.4.0` itself supports `minSdk 21`.
* Modernized the Android toolchain to build under recent Flutter/AGP: plugin `compileSdk` 31 → 35.
* Note on effective `minSdk`: the app-level floor is whatever the app's Flutter version
  requires. Flutter 3.44 raised its own minimum to `minSdkVersion 24` (Android 7.0), so apps
  built with Flutter 3.44+ get 24 regardless of this plugin; older Flutter versions retain 21.

## 2.0.0
* Migrated from `webview_flutter` pre-4.x to 4.x+ (breaking change)
* Updated Dart SDK constraint to support Dart 3.x
* Internal improvements and cleanup

## 1.1.0
* Updated Dart SDK constraint to support Dart 3.x
* Internal improvements and cleanup

## 0.4.1
* Fixed issue with google pay

## 0.4.0
* Added extended cookie handling for android 3DS extra cases
* Formatted code

## 0.3.0
* Migrated to null-safety

## 0.0.1

* First release of mobile cloudipsp functionality
