import StoreKit
import Flutter

typealias FailureCallBack = (String) -> Void

final class IAPManager {
    static let shared = IAPManager()
    private var products: [Product] = []
    private var appStoreInitiatedProduct: Product?
    private let maxPurchaseCheck: Int = 3
    private let retryInterval: TimeInterval = 2.0
    private var currentPurchaseCheckCount: Int = 0
    var isProductLoaded: Bool = false
    var channel: FlutterMethodChannel!
    
    private init() {
        self.doInitSetup()
    }
    
    private func doInitSetup() {
        /// Initialise transaction update for listen any transaction update
        self.listenForTransactionUpdates()
        
        /// Initialise handler for promotional offer
        if #available(iOS 16.4, *) {
            self.handlePromotionalOffer()
        }
    }
}

// MARK: - Transaction Listener Method
extension IAPManager {
    /// This Method Listen about pending transaction or some refund transaction so here we can finish that transaction
    private func listenForTransactionUpdates() {
        Task {
            for await verificationResult in Transaction.updates {
                switch verificationResult {
                case .verified(let transaction):
                    debugPrint("Verified transaction found: \(transaction.productID)")
                    break
                case .unverified(_, let error):
                    debugPrint("Unverified transaction: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Product load and purchase
extension IAPManager {
    
    /// This Method help to load Products with productIDs supplied in argument
    /// It will return all available Products in success callback
    /// It will return failure in enum if no product loaded Then inValidProductIds if some product is loaded then return Ids of product that not loaded and error if some error occurs in between execution
    func loadProducts(productIDs: [String], result: @escaping FlutterResult) {
        Task {
            do {
                let availableProducts = try await Product.products(for: productIDs)

                if availableProducts.count == productIDs.count {
                    self.isProductLoaded = true
                    self.products = availableProducts
                    let productJson = availableProducts.map({ self.getProductJson(from: $0) })
                    DispatchQueue.main.async {
                        result(productJson)
                    }
                } else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "E_ITEM_UNAVAILABLE", message: "Sorry, but this product is currently not available in the store.", details: nil))
                    }
                }
            } catch {
                debugPrint(error.localizedDescription)
                DispatchQueue.main.async {
                    result(FlutterError(code: "E_ITEM_UNAVAILABLE", message: "Sorry, but this product is currently not available in the store.", details: nil))
                }
            }
        }
    }
    
    /// This function is for purchase Product
    /// This function success completion return current product id if purchase success and verified
    ///  This function failure return PurchaseError enum if transaction have any problem or successful transaction cant verify then it simply return in error variable or if transaction get pending or userCanceled or unknown then return according it
    func purchaseProduct(_ productId: String, product: Product? = nil, withOffer: [String: Any]? = nil, quantity: Int = 1, result: FlutterResult?) {
        guard let product = product != nil ? product : self.products.first(where: { $0.id == productId }), let viewController = getTopViewController() else {
            DispatchQueue.main.async {
                self.channel.invokeMethod("purchase-error", arguments: self.getJsonString(["debugMessage": "Invalid product ID.", "code": "E_DEVELOPER_ERROR", "message": "Invalid product ID."]))
            }
            return
        }
        Task {
            do {
                var result: Product.PurchaseResult
                
                var purchaseOption = Product.PurchaseOption.quantity(quantity)
                if let offer = withOffer, let offerId = offer["identifier"] as? String, let keyId = offer["keyIdentifier"] as? String, let offerNonce = offer["nonce"] as? String, let signature = offer["signature"] as? Data, let timeStamp = offer["timestamp"] as? Int {
                    purchaseOption = Product.PurchaseOption.promotionalOffer(
                        offerID: offerId,
                        keyID: keyId,
                        nonce: UUID(uuidString: offerNonce)!,
                        signature: signature,
                        timestamp: timeStamp
                    )
                }
                
                if #available(iOS 18.2, *) {
                    result = try await product.purchase(confirmIn: viewController, options: [purchaseOption])
                } else {
                    // Fallback on earlier versions
                    result = try await product.purchase(options: [purchaseOption])
                }
                switch result {
                case let .success(verification):
                    switch verification {
                    case .verified(let transaction):
                        Task {
                            debugPrint("Completed purchase with Transaction: \(transaction)")
                    
                            /// For the consumable products only because currentEntitlements not return consumable products
                            /// Here we extra check we get transaction for product that we tried to purchase or not
                            /// If we get some other transaction then we return unknown error
                            if transaction.productType == .consumable {
                                if transaction.productID == product.id {
                                    Task {
                                        let jsonString = self.getJsonString(await self.getTransactionJson(from: transaction, jws: verification.jwsRepresentation))
                                        DispatchQueue.main.async {
                                            IAPManager.shared.channel.invokeMethod("purchase-updated", arguments: jsonString)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        IAPManager.shared.channel.invokeMethod("purchase-error", arguments: IAPManager.shared.getJsonString([
                                            "responseCode": 400,
                                            "debugMessage": "Purchase failed",
                                            "code": "E_USER_ERROR",
                                            "message": "Oops! Payment information invalid. Did you enter your password correctly?"
                                        ]))
                                    }
                                }
                                return
                            }
                            
                            /// Here we add currentEntitlements so we can re-verify about purchase and unlock premium according that
                            self.checkForTransactionAvailablity(transaction: transaction) { isValid in
                                if isValid {
                                    Task {
                                        let jsonString = self.getJsonString(await self.getTransactionJson(from: transaction, jws: verification.jwsRepresentation))
                                        DispatchQueue.main.async {
                                            IAPManager.shared.channel.invokeMethod("purchase-updated", arguments: jsonString)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        IAPManager.shared.channel.invokeMethod("purchase-error", arguments: IAPManager.shared.getJsonString([
                                            "responseCode": 404,
                                            "debugMessage": "Transaction not found.",
                                            "code": "E_TRANSACTION_NOT_FOUND",
                                            "message": "We couldn't verify your purchase. Please try again later."
                                        ]))
                                    }
                                }
                            }
                        }
                        break
                    case .unverified(_,let error):
                        debugPrint("Unverified purchase. Might be jailbroken. Error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            IAPManager.shared.channel.invokeMethod("purchase-error", arguments: IAPManager.shared.getJsonString([
                                "responseCode": 403,
                                "debugMessage": "Unverified purchase. Possibly jailbroken device.",
                                "code": "E_SERVICE_ERROR",
                                "message": "Unable to process the transaction: your device is not allowed to make purchases."
                            ]))
                        }
                        break
                    }
                case .pending:
                    DispatchQueue.main.async {
                        IAPManager.shared.channel.invokeMethod("purchase-error", arguments: IAPManager.shared.getJsonString([
                            "responseCode": 202,
                            "debugMessage": "Purchase is pending approval.",
                            "code": "E_USER_ERROR",
                            "message": "Payment is not allowed on this device. If you are the one authorized to make purchases on this device, you can turn payments on in Settings."
                        ]))
                    }
                    break
                case .userCancelled:
                    debugPrint("User Cancelled!")
                    DispatchQueue.main.async {
                        IAPManager.shared.channel.invokeMethod("purchase-error", arguments: IAPManager.shared.getJsonString([
                            "responseCode": 499,
                            "debugMessage": "User cancelled the transaction.",
                            "code": "E_USER_CANCELLED",
                            "message": "Cancelled."
                        ]))
                    }
                    break
                @unknown default:
                    debugPrint("Unknown error while purchasing.")
                    DispatchQueue.main.async {
                        IAPManager.shared.channel.invokeMethod("purchase-error", arguments: IAPManager.shared.getJsonString([
                            "responseCode": 520,
                            "debugMessage": "Unknown error occurred.",
                            "code": "E_UNKNOWN",
                            "message": "An unknown or unexpected error has occurred. Please try again later."
                        ]))
                    }
                }
            } catch {
                debugPrint("Exception during purchase: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    IAPManager.shared.channel.invokeMethod("purchase-error", arguments: IAPManager.shared.getJsonString([
                        "responseCode": 500,
                        "debugMessage": "\(error.localizedDescription)",
                        "code": "E_UNKNOWN",
                        "message": "An unknown or unexpected error has occurred. Please try again later."
                    ]))
                }
            }
        }
    }
    
    func checkForTransactionAvailablity(transaction: Transaction, isValidTransaction: @escaping ((Bool) -> Void)) {
        func retry() {
            if self.currentPurchaseCheckCount < self.maxPurchaseCheck {
                self.currentPurchaseCheckCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryInterval) {
                    self.checkForTransactionAvailablity(transaction: transaction, isValidTransaction: isValidTransaction)
                }
            } else {
                self.currentPurchaseCheckCount = 0
                isValidTransaction(false)
            }
        }
        
        self.getActiveTransaction(success: { allPurchasedProductIds in
            if allPurchasedProductIds.contains(where: { $0.productID == transaction.productID }) {
                isValidTransaction(true)
            } else {
                retry()
            }
        }, failure: { error in
            retry()
        })
    }
}

// MARK: - Transaction Information Methods
extension IAPManager {
    /// This function fetch all active transaction
    /// This functions success callback return productIds of currently active plans
    /// This function failure callback return failure message if no plan has been purchased or verified transaction is currently not active
    private func getActiveTransaction(success: @escaping ([Transaction]) -> Void, failure: @escaping FailureCallBack) {
        Task {
            var purchasedPlan: [Transaction] = []
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.revocationDate != nil { continue }
                    debugPrint(transaction)
                    purchasedPlan.append(transaction)
                case .unverified(_, let error):
                    debugPrint("Verification Failed: \(error.localizedDescription)")
                    break
                }
            }
            purchasedPlan.isEmpty ? failure("No active plan available") : success(purchasedPlan)
        }
    }
    
    func getPurchaseHistory(result: @escaping FlutterResult) {
        Task {
            var purchasedPlan: [Transaction] = []
            var transactionData: [[String: Any]] = []
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.revocationDate != nil { continue }
                    debugPrint(transaction)
                    purchasedPlan.append(transaction)
                    await transactionData.append(self.getTransactionJson(from: transaction, jws: result.jwsRepresentation))
                case .unverified(_, _):
                    break
                }
            }
            DispatchQueue.main.async {
                result(transactionData)
            }
        }
    }
}

// MARK: - Restore Purchase
extension IAPManager {
    
    /// This function is for restore purchase
    /// This functions success callback return available productIds that is currently active
    /// This function failure callback return enum in which if user purchased before but that is expired, user never purchased or any other error message
    func syncWithAppStore(result: @escaping FlutterResult) {
        Task {
            do {
                try await AppStore.sync()
                DispatchQueue.main.async {
                    result(true)
                }
            } catch {
                debugPrint(error.localizedDescription)
                DispatchQueue.main.async {
                    result(false)
                }
            }
        }
    }
}

// MARK: - Promotional Offer Handler
extension IAPManager {
    
    /// This is for promotional purchase
    /// This function return success completion for productId of try to purchase product if purchased successfully
    /// This function return failure completion for any error in purchase
    @available(iOS 16.4, *)
    private func handlePromotionalOffer() {
        Task {
            for await purchaseIntent in PurchaseIntent.intents {
                self.appStoreInitiatedProduct = purchaseIntent.product
                DispatchQueue.main.async {
                    IAPManager.shared.channel.invokeMethod("iap-promoted-product", arguments: purchaseIntent.id)
                }
            }
        }
    }
}

// MARK: - Product Helping method
extension IAPManager {
    func getPendingTransaction(result: @escaping FlutterResult) {
        var pendingTransactions: [[String: Any]] = []
        Task {
            for await result in Transaction.unfinished {
                switch result {
                case .unverified(_, let error):
                    debugPrint("Unverified Error: \(error.localizedDescription)")
                    break
                case .verified(let transaction):
                    debugPrint("Pending Transaction: \(transaction.productID)")
                    await pendingTransactions.append(self.getTransactionJson(from: transaction, jws: result.jwsRepresentation))
                }
            }
            DispatchQueue.main.async {
                result(pendingTransactions)
            }
        }
    }
    
    func completeTransaction(id: String, result: @escaping FlutterResult) {
        Task {
            for await resut in Transaction.unfinished {
                switch resut {
                case .unverified(_, _):
                    break
                case .verified(let transaction):
                    if String(transaction.id) == id {
                        await transaction.finish()
                        DispatchQueue.main.async {
                            result(id)
                        }
                    }
                }
            }
        }
    }
    
    func showRedeemCodeSheet(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *), let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene  {
            Task {
                do {
                    try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
                    DispatchQueue.main.async {
                        result("present PromoCodes")
                    }
                } catch {
                    DispatchQueue.main.async {
                        result("can't able to present PromoCodes")
                    }
                }
            }
        }  else {
            DispatchQueue.main.async {
                result("the functionality is available starting from ios 16.0")
            }
        }
    }
    
    func getAppStoreInitiatedProducts(result: @escaping FlutterResult) {
        if let product = self.appStoreInitiatedProduct {
            DispatchQueue.main.async {
                result([self.getProductJson(from: product)])
            }
        } else {
            DispatchQueue.main.async {
                result([])
            }
        }
    }
    
    func clearAllTransaction(result: @escaping FlutterResult) {
        Task {
            for await result in Transaction.unfinished {
                switch result {
                case .unverified(_, _):
                    break
                case .verified(let transaction):
                    await transaction.finish()
                }
            }
            DispatchQueue.main.async {
                result("Cleared transactions")
            }
        }
    }
    
    func getPromotedProduct(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            result(self.appStoreInitiatedProduct?.id ?? NSNull())
        }
    }
    
    func requestPromotedProduct(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if let product = self.appStoreInitiatedProduct {
                self.appStoreInitiatedProduct = nil
                self.purchaseProduct("", product: product, result: nil)
                result(product.id)
            } else {
                result(FlutterError(code: "E_DEVELOPER_ERROR", message: "Invalid product ID.", details: nil))
            }
        }
    }
}

// MARK: - Utility Methods
extension IAPManager {
    private func getTransactionJson(from transaction: Transaction, jws: String) async -> [String: Any] {
        return [
            "productId": transaction.productID,
            "transactionId": "\(transaction.id)",
            "transactionDate": "\(transaction.purchaseDate.timeIntervalSince1970 * 1000)",
            "originalTransactionDateIOS": "\(transaction.originalPurchaseDate.timeIntervalSince1970 * 1000)",
            "originalTransactionIdentifierIOS": "\(transaction.originalID)",
            "transactionStateIOS": await transaction.subscriptionStatus?.state.rawValue ?? -1,
            "transactionReceipt": transaction.jsonRepresentation.base64EncodedString(),
            "jwsRepresentation": jws
        ]
    }
    
    private func getProductJson(from product: Product) -> [String: Any] {
        var json: [String: Any] = [:]
        json["productId"] = product.id
        json["price"] = "\(product.price)"
        json["currency"] = product.priceFormatStyle.currencyCode
        json["localizedPrice"] = product.displayPrice
        json["title"] = product.displayName
        json["description"] = product.description
        if let introOffer = product.subscription?.introductoryOffer {
            var paymentMode = ""
            var numberOfPeriods = "0"
            switch introOffer.paymentMode {
            case .freeTrial:
                paymentMode = "FREETRIAL"
                numberOfPeriods = "\(introOffer.period.value)"
            case .payAsYouGo:
                paymentMode = "PAYASYOUGO"
                numberOfPeriods = "\(introOffer.periodCount)"
            case .payUpFront:
                paymentMode = "PAYUPFRONT"
                numberOfPeriods = "\(introOffer.period.value)"
            default:
                break
            }
            var subscriptionPeriods = ""
            switch introOffer.period.unit {
            case .day:
                subscriptionPeriods = "DAY"
            case .week:
                subscriptionPeriods = "WEEK"
            case .month:
                subscriptionPeriods = "MONTH"
            case .year:
                subscriptionPeriods = "YEAR"
            default:
                subscriptionPeriods = ""
            }
            json["introductoryPrice"] = introOffer.displayPrice
            json["introductoryPricePaymentModeIOS"] = paymentMode
            json["introductoryPriceNumberOfPeriodsIOS"] = numberOfPeriods
            json["introductoryPriceSubscriptionPeriodIOS"] = subscriptionPeriods
            json["introductoryPriceNumberIOS"] = "\(introOffer.price)"
        }
        
        if let subscriptionOffer = product.subscription?.promotionalOffers {
            var discounts: [[String: Any]] = []
            
            for discount in subscriptionOffer {
                var paymentMode = ""
                var numberOfPeriods = "0"
                switch discount.paymentMode {
                case .freeTrial:
                    paymentMode = "FREETRIAL"
                    numberOfPeriods = "\(discount.period.value)"
                case .payAsYouGo:
                    paymentMode = "PAYASYOUGO"
                    numberOfPeriods = "\(discount.periodCount)"
                case .payUpFront:
                    paymentMode = "PAYUPFRONT"
                    numberOfPeriods = "\(discount.period.value)"
                default:
                    break
                }
                var subscriptionPeriods = ""
                switch discount.period.unit {
                case .day: subscriptionPeriods = "DAY"
                case .week: subscriptionPeriods = "WEEK"
                case .month: subscriptionPeriods = "MONTH"
                case .year: subscriptionPeriods = "YEAR"
                @unknown default: subscriptionPeriods = ""
                }
                var discountType = ""
                if #available(iOS 12.2, *) {
                    switch discount.type {
                    case .introductory: discountType = "INTRODUCTORY"
                    case .promotional: discountType = "SUBSCRIPTION"
                    default: discountType = ""
                    }
                }
                
                discounts.append([
                    "identifier": discount.id ?? "",
                    "type": discountType,
                    "numberOfPeriods": numberOfPeriods,
                    "price": Double(truncating: discount.price as NSNumber),
                    "localizedPrice": discount.displayPrice,
                    "paymentMode" : paymentMode,
                    "subscriptionPeriod": subscriptionPeriods
                ])
            }
            json["discounts"] = discounts
        }
        
        if let subscriptionPeriod = product.subscription?.subscriptionPeriod {
            json["subscriptionPeriodNumberIOS"] = "\(subscriptionPeriod.value)"
            json["subscriptionPeriodUnitIOS"] = "\(subscriptionPeriod.unit)"
        }
    
        return json
    }
    
    private func getJsonString(_ dict: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            debugPrint("Error: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first else { return nil }
        var topVC = window.rootViewController
        while let presentedVC = topVC?.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
}
