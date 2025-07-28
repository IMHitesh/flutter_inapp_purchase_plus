## <img src="https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png" alt="Flutter Logo" width="15" />  Flutter V2

This packages is compatible with flutter v2.

## 📱 Platform Support
| OS | Minimum Version |
|:----------:|:----------:|
| 🍎 iOS    |  iOS 15+  |
| 🤖 Android   | Api Level 21  |
| X-Code | 16.3+ |
| JVM | 17+ |


## 🔍 What this plugin do
This is an `In App Purchase` plugin for Flutter, forked from the original [flutter_inapp_purchase](https://github.com/hyochan/flutter_inapp_purchase) package.

We are actively maintaining and modernizing the codebase with support for the latest platform APIs:

 - ✅ **Apple (iOS/macOS)**: We're adding support for **`StoreKit 2`**, Apple's modern in-app purchase framework. The original plugin deprecated Apple platform support, so this fork restores and extends compatibility using the latest StoreKit APIs.

- ✅ **Android**: Integrated support for Google Play Billing Library version **`8.0.0`**, aligning with the latest Play Store requirements and security enhancements.

This plugin is intended to provide a future-proof, platform-compliant solution for handling in-app purchases across Flutter applications.

`PR` is always welcomed.

## 🚀 Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).

## ⚒️ Methods

| Function                         |                                                                                     Parameters                                                                                      |        Return         | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| :--------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| initConnection               |                                                                                                                                                                                |       `String`        | Prepare IAP module. Must be called on Android before any other purchase flow methods. In ios, it will simply call `canMakePayments` method and return value.                                                                                                                                                                                                                                                                                                             |
| getProducts                  |                                                                        `List<String>` Product IDs/skus                                                                         |    `List<IAPItem>`    | Get a list of products (consumable and non-consumable items, but not subscriptions).2.                                                                                                                                                            |
| getSubscriptions             |                                                                      `List<String>` Subscription IDs/skus                                                                      |    `List<IAPItem>`    | Get a list of subscriptions. Note: On iOS this method has the same output as `getProducts`.                                                                                                                                                                                                                                                                                                  |
| getPurchaseHistory           |                                                                                                                                                                                |    `List<IAPItem>`    | ⚠️ Deprecated: Previously returned all purchases regardless of consumption status. Now limited to only currently available (non-consumed or active) purchases, as permitted by the platform                                                                                                                                                                                                                                                                                                                                                                        |
| getAvailablePurchases        |                                                                                                                                                                                | `List<PurchasedItem>` | Get all purchases made by the user either non-consumable, or haven't been consumed yet `In iOS it not return consumable purchases`                                                                                                                                                                                                                                                                                                                                                          |
| getAppStoreInitiatedProducts |                                                                                                                                                                                |    `List<IAPItem>`    | If the user has initiated a purchase directly on the App Store, the products that the user is attempting to purchase will be returned here. (iOS only) Note: On iOS versions earlier than 16.4 this method will always return an empty list, Always returns an empty list on Android. |
| requestSubscription          | `String` sku, `String` oldSkuAndroid?, `int` prorationModeAndroid?, `String` obfuscatedAccountIdAndroid?, `String` obfuscatedProfileIdAndroid?, `String` purchaseTokenAndroid? |         Null          | Create (request) a subscription to a sku. For upgrading/downgrading subscription on Android pass second parameter with current subscription ID, on iOS this is handled automatically by store. `purchaseUpdatedListener` will receive the result.                                                                                                                                                                                                                        |
| requestPurchase              |                               `String` sku, `String` obfuscatedAccountIdAndroid?, `String` obfuscatedProfileIdAndroid?, `String` purchaseToken?                                |         Null          | Request a purchase. `purchaseUpdatedListener` will receive the result.                                                                                                                                                                                                                                                                                                                                                                                                   |
| finishTransactionIOS         |                                                                         `String` purchaseTokenAndroid                                                                          |   `PurchaseResult`    | Send finishTransaction call to Apple IAP server. Call this function after receipt validation process                                                                                                                                                                                                                                                                                                                                                                     |
| acknowledgePurchaseAndroid   |                                                                             `String` purchaseToken                                                                             |   `PurchaseResult`    | Acknowledge a product (on Android) for `non-consumable` and `subscription` purchase. No-op on iOS.                                                                                                                                                                                                                                                                                                                                                                       |
| consumePurchaseAndroid       |                                                                             `String` purchaseToken                                                                             |   `PurchaseResult`    | Consume a product (on Android) for `consumable` purchase. No-op on iOS.                                                                                                                                                                                                                                                                                                                                                                                                  |
| finishTransaction            |                                                                 `String` purchaseToken, `bool` isConsumable? }                                                                 |   `PurchaseResult`    | Send finishTransaction call that abstracts all `acknowledgePurchaseAndroid`, `finishTransactionIOS`, `consumePurchaseAndroid` methods.                                                                                                                                                                                                                                                                                                                                   |
| endConnection                |                                                                                                                                                                                |       `String`        | End billing connection.                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| consumeAllItems              |                                                                                                                                                                                |       `String`        | Manually consume all items in android. Do NOT call if you have any non-consumables (one time purchase items). No-op on iOS.                                                                                                                                                                                                                                                                                                                                              |
| validateReceiptIos           |                                                                `Map<String,String>` receiptBody, `bool` isTest                                                                 |    `http.Response`    | Validate receipt for ios.                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| validateReceiptAndroid       |                                  `String` packageName, `String` productId, `String` productToken, `String` accessToken, `bool` isSubscription                                  |    `http.Response`    | Validate receipt for android.                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| showPromoCodesIOS            |                                                                                                                                                                                |                       | Show redeem codes in iOS.                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| appStoreSync            |          |       | This iOS Specific method to sync with AppStore, After successfully calling this method, call `getAvailablePurchases` for get active purchases.
| showInAppMessageAndroid      |                                                                                                                                                                                |                       | Google Play will show users messaging during grace period and account hold once per day and provide them an opportunity to fix their payment without leaving the app                                                                                                                                                                                                                                                                                                                                                                                                                                          |

## 🛒 Purchase flow in `flutter_inapp_purchase_plus`

> When you've successfully received result from `purchaseUpdated` listener, you'll have to `verify` the purchase either by `acknowledgePurchaseAndroid`, `consumePurchaseAndroid`, `finishTransactionIOS` depending on the purchase types or platforms. You'll have to use `consumePurchaseAndroid` for `consumable` products and `android` and `acknowledgePurchaseAndroid` for `non-consumable` products either `subscription`. For `ios`, there is no differences in `verifying` purchases. You can just call `finishTransaction`. If you do not verify the purchase, it will be refunded within 3 days to users. Lastly, if you want to abstract three different methods into one, consider using `finishTransaction` method.

## 📊 Data Types

- IAPItem

  ```dart
  final String productId;
  final String price;
  final String currency;
  final String localizedPrice;
  final String title;
  final String description;
  final String introductoryPrice;

  /// ios only
  final String subscriptionPeriodNumberIOS;
  final String subscriptionPeriodUnitIOS;
  final String introductoryPricePaymentModeIOS;
  final String introductoryPriceNumberOfPeriodsIOS;
  final String introductoryPriceSubscriptionPeriodIOS;

  /// android only
  final String subscriptionPeriodAndroid;
  final String introductoryPriceCyclesAndroid;
  final String introductoryPricePeriodAndroid;
  final String freeTrialPeriodAndroid;
  final String signatureAndroid;

  final String iconUrl;
  final String originalJson;
  final String originalPrice;
  ```

- PurchasedItem

  ```dart
  final String productId;
  final String transactionId;
  final DateTime transactionDate;
  final String transactionReceipt;
  final String purchaseToken;

  // Android only
  final String dataAndroid;
  final String signatureAndroid;
  final bool autoRenewingAndroid;
  final bool isAcknowledgedAndroid;
  final int purchaseStateAndroid;

  // iOS only
  final DateTime originalTransactionDateIOS;
  final String originalTransactionIdentifierIOS;
  ```

## ⬇️ Install

Add `flutter_inapp_purchase_plus` as a dependency in pubspec.yaml

For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

## 📝 Usage Guide

#### Android `connect` and `endConnection`

- You should start the billing service in android to use its funtionalities. We recommend you to use `initConnection` getter method in `initState()`. Note that this step is necessary in `ios` also from `flutter_inapp_purchase_plus` which will also register the `purchaseUpdated` and `purchaseError` `Stream`.

  ```dart
    /// start connection for android
    @override
    void initState() {
      super.initState();
      asyncInitState(); // async is not allowed on initState() directly
    }

    void asyncInitState() async {
      await FlutterInappPurchase.instance.initConnection;
    }
  ```

- You should end the billing service in android when you are done with it. Otherwise it will be keep running in background. We recommend to use this feature in `dispose()`.

- Additionally, we've added `connectionUpdated` stream just in case if you'd like to monitor the connection.

  ```
  _conectionSubscription = FlutterInappPurchase.connectionUpdated.listen((connected) {
    print('connected: $connected');
  });
  ```

  > You can see how you can use this in detail in `example` project.

  ```dart
    /// start connection for android
    @override
    void dispose() async{
      super.dispose();
      await FlutterInappPurchase.instance.endConnection;
    }
  ```

#### Get IAP items

```dart
void getItems () async {
  List<IAPItem> items = await FlutterInappPurchase.instance.getProducts(_productLists);
  for (var item in items) {
    print('${item.toString()}');
    this._items.add(item);
  }
}
```

#### Purchase Item

```dart
void purchase() {
  FlutterInappPurchase.instance.requestPurchase(item.productId);
}
```

#### Register listeners to receive purchase

```dart
StreamSubscription _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen((productItem) {
  print('purchase-updated: $productItem');
});

StreamSubscription _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen((purchaseError) {
  print('purchase-error: $purchaseError');
});
```

#### Remove listeners when ending connection

```dart
_purchaseUpdatedSubscription.cancel();
_purchaseUpdatedSubscription = null;
_purchaseErrorSubscription.cancel();
_purchaseErrorSubscription = null;
```

#### Receipt validation

We support receipt validation. For Android, you need separate json file from the service account to get the `access_token` from `google-apis`, therefore it is impossible to implement serverless. You should have your own backend and get `access_token`. With `access_token` you can simply call `validateReceiptAndroid` method we implemented. Further reading is [here](https://stackoverflow.com/questions/35127086/android-inapp-purchase-receipt-validation-google-play?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).
Currently, serverless receipt validation is possible using `validateReceiptIos` method. The first parameter, you should pass `transactionReceipt` which returns after `requestPurchase`. The second parameter, you should pass whether this is `test` environment. If `true`, it will request to `sandbox` and `false` it will request to `production`.

```dart
validateReceipt() async {
  var receiptBody = {
    'receipt-data': purchased.transactionReceipt,
    'password': '******'
  };
  const result = await validateReceiptIos(receiptBody, false);
  console.log(result);
}
```

For further information, please refer to [guide](https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html).

#### App Store initiated purchases

When the user starts an in-app purchase in the App Store, the transaction continues in your app, the product will then be added to a list that you can access through the method `getAppStoreInitiatedProducts`. This means you can decide how and when to continue the transaction.
To continue the transaction simple use the standard purchase flow from this plugin.

```dart
void checkForAppStoreInitiatedProducts() async {
  List<IAPItem> appStoreProducts = await FlutterInappPurchase.instance.getAppStoreInitiatedProducts(); // Get list of products
  if (appStoreProducts.length > 0) {
    _requestPurchase(appStoreProducts.last); // Buy last product in the list
  }
}
```

### Sync with AppStore (Restore Purchase)

This method is used to synchronize the app with the App Store and restore any previously purchased non-consumable items or active subscriptions. It's particularly helpful in scenarios such as:

- After reinstalling the app

- When a user logs in on a new device

- To manually trigger purchase restoration

```dart
  void retsorePurchase() async {
    final result = await FlutterInappPurchase.instance.restorePurchases();
    if (result) {
      final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
      // This purchase is list of PurchasedItem
    }
  }
```

## 🔐 ProGuard

If you have enabled proguard you will need to add the following rules to your `proguard-rules.pro`

```
#In app Purchase
-keep class com.amazon.** {*;}
-keep class com.noble.** { *; }
-keep class com.android.vending.billing.**
-dontwarn com.amazon.**
-keepattributes *Annotation*
```

> 🔔 **Notice:** This is a fork of [flutter_inapp_purchase](https://github.com/hyochan/flutter_inapp_purchase), enhanced with additional updates and improvements by [Hitesh Surani](https://github.com/IMHitesh) and team.