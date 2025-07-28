import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_inapp_purchase_plus/flutter_inapp_purchase.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Inapp Plugin by Noble App Solutions'),
          ),
          body: const InApp()),
    );
  }
}

class InApp extends StatefulWidget {
  const InApp({Key? key}) : super(key: key);

  @override
  _InAppState createState() => new _InAppState();
}

class _InAppState extends State<InApp> {
  late dynamic _purchaseUpdatedSubscription;
  late dynamic _purchaseErrorSubscription;
  late dynamic _connectionSubscription;
  final List<String> _productLists = Platform.isAndroid
      ? [
          'android.test.purchased',
          'point_1000',
          '5000_point',
          'android.test.canceled',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  List<IAPItem> _items = [];
  List<PurchasedItem> _purchases = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    if (_connectionSubscription != null) {
      _connectionSubscription.cancel();
      _connectionSubscription = null;
    }
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // prepare
    var result = await FlutterInappPurchase.instance.initialize();
    debugPrint('result: $result');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    // refresh items for android
    try {
      String msg = await FlutterInappPurchase.instance.consumeAll();
      debugPrint('consumeAllItems: $msg');
    } catch (err) {
      debugPrint('consumeAllItems error: $err');
    }

    _connectionSubscription =
        FlutterInappPurchase.connectionUpdated.listen((connected) {
      debugPrint('connected: $connected');
    });

    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) {
      debugPrint('purchase-updated: $productItem');
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      debugPrint('purchase-error: $purchaseError');
    });
  }

  void _requestPurchase(IAPItem item) {
    FlutterInappPurchase.instance.requestPurchase(item.productId!);
  }

  Future _getProduct() async {
    List<IAPItem> items =
        await FlutterInappPurchase.instance.getProducts(_productLists);
    for (var item in items) {
      debugPrint('${item.toString()}');
      _items.add(item);
    }

    setState(() {
      _items = items;
      _purchases = [];
    });
  }

  Future _getPurchases() async {
    List<PurchasedItem>? items =
        await FlutterInappPurchase.instance.getAvailablePurchases();
    for (var item in items!) {
      debugPrint('${item.toString()}');
      _purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  Future _getPurchaseHistory() async {
    List<PurchasedItem>? items =
        await FlutterInappPurchase.instance.getPurchaseHistory();
    for (var item in items!) {
      debugPrint('${item.toString()}');
      _purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  List<Widget> _renderInApps() {
    List<Widget> widgets = _items
        .map((item) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  MaterialButton(
                    color: Colors.orange,
                    onPressed: () {
                      debugPrint("---------- Buy Item Button Pressed");
                      _requestPurchase(item);
                    },
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 48.0,
                            alignment: const Alignment(-1.0, 0.0),
                            child: const Text('Buy Item'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
        .toList();
    return widgets;
  }

  List<Widget> _renderPurchases() {
    List<Widget> widgets = _purchases
        .map((item) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),
            ))
        .toList();
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width - 20;
    double buttonWidth = (screenWidth / 3) - 20;

    return Container(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                'Running on: ${Platform.operatingSystem} - ${Platform.operatingSystemVersion}\n',
                style: const TextStyle(fontSize: 18.0),
              ),
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Container(
                        width: buttonWidth,
                        height: 60.0,
                        margin: const EdgeInsets.all(7.0),
                        child: MaterialButton(
                          color: Colors.amber,
                          padding: const EdgeInsets.all(0.0),
                          onPressed: () async {
                            debugPrint(
                                "---------- Connect Billing Button Pressed");
                            await FlutterInappPurchase.instance.initialize();
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            alignment: const Alignment(0.0, 0.0),
                            child: const Text(
                              'Connect Billing',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: buttonWidth,
                        height: 60.0,
                        margin: const EdgeInsets.all(7.0),
                        child: MaterialButton(
                          color: Colors.amber,
                          padding: const EdgeInsets.all(0.0),
                          onPressed: () async {
                            debugPrint(
                                "---------- End Connection Button Pressed");
                            await FlutterInappPurchase.instance.finalize();
                            if (_purchaseUpdatedSubscription != null) {
                              _purchaseUpdatedSubscription.cancel();
                              _purchaseUpdatedSubscription = null;
                            }
                            if (_purchaseErrorSubscription != null) {
                              _purchaseErrorSubscription.cancel();
                              _purchaseErrorSubscription = null;
                            }
                            setState(() {
                              _items = [];
                              _purchases = [];
                            });
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            alignment: const Alignment(0.0, 0.0),
                            child: const Text(
                              'End Connection',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Container(
                            width: buttonWidth,
                            height: 60.0,
                            margin: const EdgeInsets.all(7.0),
                            child: MaterialButton(
                              color: Colors.green,
                              padding: const EdgeInsets.all(0.0),
                              onPressed: () {
                                debugPrint(
                                    "---------- Get Items Button Pressed");
                                _getProduct();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                alignment: const Alignment(0.0, 0.0),
                                child: const Text(
                                  'Get Items',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            )),
                        Container(
                            width: buttonWidth,
                            height: 60.0,
                            margin: const EdgeInsets.all(7.0),
                            child: MaterialButton(
                              color: Colors.green,
                              padding: const EdgeInsets.all(0.0),
                              onPressed: () {
                                debugPrint(
                                    "---------- Get Purchases Button Pressed");
                                _getPurchases();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                alignment: const Alignment(0.0, 0.0),
                                child: const Text(
                                  'Get Purchases',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            )),
                        Container(
                            width: buttonWidth,
                            height: 60.0,
                            margin: const EdgeInsets.all(7.0),
                            child: MaterialButton(
                              color: Colors.green,
                              padding: const EdgeInsets.all(0.0),
                              onPressed: () {
                                debugPrint(
                                    "---------- Get Purchase History Button Pressed");
                                _getPurchaseHistory();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                alignment: const Alignment(0.0, 0.0),
                                child: const Text(
                                  'Get Purchase History',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            )),
                      ]),
                ],
              ),
              Column(
                children: _renderInApps(),
              ),
              Column(
                children: _renderPurchases(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
