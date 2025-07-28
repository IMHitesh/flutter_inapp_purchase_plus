import Foundation
import StoreKit
import Flutter

public class FlutterInappPurchasePlugin: NSObject, FlutterPlugin {
    
    static var channel: FlutterMethodChannel!
    public static func register(with registrar: any FlutterPluginRegistrar) {
        self.channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger())
        let instance = FlutterInappPurchasePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        IAPManager.shared.channel = FlutterInappPurchasePlugin.channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if call.method == "getPlatformVersion" {
                
                result("iOS \(UIDevice.current.systemVersion)")
            } else if call.method == "canMakePayments" {
                result("\(AppStore.canMakePayments)")
            } else if call.method == "endConnection" {
                result("Billing client ended")
            } else if call.method == "getItems" {
                if let argument = call.arguments as? [String: Any], let productIds = argument["skus"] as? [String] {
                    IAPManager.shared.loadProducts(productIDs: productIds, result: result)
                } else {
                    result(FlutterError(code: "ERROR", message: "Invalid or missing arguments!", details: nil))
                }
            } else if call.method == "buyProduct" {
                if let argument = call.arguments as? [String: Any], let productId = argument["sku"] as? String {
                    IAPManager.shared.purchaseProduct(productId, result: result)
                } else {
                    result(FlutterError(code: "ERROR", message: "Invalid or missing arguments!", details: nil))
                }
            } else if call.method == "requestProductWithOfferIOS" {
                guard let arguments = call.arguments as? [String: Any],
                      let sku = arguments["sku"] as? String,
                      let discountOffer = arguments["withOffer"] as? [String: Any] else {
                    result(FlutterError(code: "ERROR", message: "Invalid or missing arguments!", details: nil))
                    return
                }
                IAPManager.shared.purchaseProduct(sku, withOffer: discountOffer, result: result)
            } else if call.method == "requestProductWithQuantityIOS" {
                guard let args = call.arguments as? [String: Any],
                      let sku = args["sku"] as? String,
                      let quantity = args["quantity"] as? String else {
                    result(FlutterError(code: "ERROR", message: "Invalid or missing arguments!", details: nil))
                    return
                }
                IAPManager.shared.purchaseProduct(sku, quantity: Int(quantity) ?? 1, result: result)
            } else if call.method == "getPromotedProduct" {
                IAPManager.shared.getPromotedProduct(result: result)
            } else if call.method == "requestPromotedProduct" {
                IAPManager.shared.requestPromotedProduct(result: result)
            } else if call.method == "requestReceipt" {
                guard let receiptURL = Bundle.main.appStoreReceiptURL, let receiptData = try? Data(contentsOf: receiptURL) else {
                    result(FlutterError(code: "E_UNKNOWN", message: "Invalid receipt", details: nil))
                    return
                }
                result(receiptData.base64EncodedString(options: []))
            } else if call.method == "getPendingTransactions" {
                IAPManager.shared.getPendingTransaction(result: result)
            } else if call.method == "finishTransaction" {
                if let argument = call.arguments as? [String: Any], let transactionId = argument["transactionIdentifier"] as? String {
                    IAPManager.shared.completeTransaction(id: transactionId, result: result)
                } else {
                    result(FlutterError(code: "ERROR", message: "Invalid or missing arguments!", details: nil))
                }
            } else if call.method == "appStoreSync" {
                IAPManager.shared.syncWithAppStore(result: result)
            } else if call.method == "clearTransaction" {
                IAPManager.shared.clearAllTransaction(result: result)
            } else if call.method == "getAvailableItems" {
                IAPManager.shared.getPurchaseHistory(result: result)
            } else if call.method == "getAppStoreInitiatedProducts" {
                IAPManager.shared.getAppStoreInitiatedProducts(result: result)
            } else if call.method == "showRedeemCodesIOS" {
                IAPManager.shared.showRedeemCodeSheet(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
}
