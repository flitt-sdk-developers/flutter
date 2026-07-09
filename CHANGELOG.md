## 2.1.0
* Migrated the Google Pay button to the official `pay` package's native
  `RawGooglePayButton` (Hybrid Composition). Removed the custom
  `google_pay_button_view` platform view and `GooglePayButtonPlugin`.
* The `GooglePayButton` public API is unchanged; the Flitt tokenization and 3DS
  flow (`Cloudipsp.googlePay/googlePayToken`) is unchanged.
* Requires `minSdkVersion 23` and Dart 3.1+ (imposed by the `pay` package).
* `borderRadius` now maps to the button corner radius; `width`/`height` are
  applied via an enclosing box and subject to the native button's minimum size.

## 2.0.1
* Fixed Google Pay button never rendering: the `google_pay_button_view` platform view is now
  registered by the main plugin (`FlittMobilePlugin`), so it is actually loaded by the engine.
  Previously the factory lived in a plugin class that was never registered.
* Fixed Google Pay button not rendering: the native button is now created only after the
  payment configuration has loaded, eliminating a race that could leave the button blank.

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
