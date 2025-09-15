## 1.0.4
- **Google Play Billing Library**
  - Google Play Billing Library v8.0 deprecated `SubscriptionUpdateParams.setReplaceProrationMode()` and replaced it with `SubscriptionUpdateParams.setReplacementMode()`. Accordingly, the enum has changed from `ProrationMode` to `ReplacementMode`.

## 1.0.3
- Deprecation cleanup: Eliminated legacy implementations tied to Android Billing Client v8.

## 1.0.2

### Fixed
- Resolved issue where iOS purchase date defaulted to 1970 (Unix epoch).
- iOS `transactionReceipt` is now included with `PurchasedItem`.

## 1.0.1

### 🚀 Major Updates
- ✅ **Added support for Google Play Billing Library v8.0.0** on Android.
- ✅ **Integrated initial support for StoreKit 2** on Apple platforms (iOS/macOS).
- ❗ Purchase inventory API now returns only **currently available purchases** (consumed/historical purchases excluded, per platform limitations).

## 0.0.1

- Initial release 
- Moved code from [flutter_inapp_purchase](https://github.com/hyochan/flutter_inapp_purchase)
- Storekit 2 support added for iOS
