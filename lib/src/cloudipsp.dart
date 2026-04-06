import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import './api.dart';
import './cloudipsp_error.dart';
import './cloudipsp_web_view_confirmation.dart';
import './credit_card.dart';
import './fee_calculation_response.dart';
import './native.dart';
import './order.dart';
import './platform_specific.dart';
import './receipt.dart';
import 'bank.dart';
import 'bankRedirectDetails.dart';

typedef void CloudipspWebViewHolder(CloudipspWebViewConfirmation confirmation);

abstract class Cloudipsp {
  factory Cloudipsp(
          int merchantId, CloudipspWebViewHolder cloudipspWebViewHolder) =
      CloudipspImpl;

  int get merchantId;

  Future<bool> supportsApplePay();

  Future<bool> supportsGooglePay();

  Future<String> getToken(Order order);

  Future<Receipt> pay(CreditCard creditCard, Order order);

  Future<Receipt> payToken(CreditCard card, String token);

  Future<Receipt> applePay(Order order);

  Future<Receipt> applePayToken(String token);

  Future<Receipt> googlePay(Order order, dynamic config);

  Future<Receipt> googlePayToken(String token, dynamic config);

  Future<dynamic> initializePaymentConfig(Order? order, {String? token});

  Future<List<Bank>> getAvailableBankList(Order order);

  Future<List<Bank>> getAvailableBankListByToken(String token);

  Future<BankRedirectDetails> initiateBankPayment(Bank bank, Order order,
      {bool autoRedirect = true});

  Future<BankRedirectDetails> initiateBankPaymentByToken(
      String token, Bank bank,
      {bool autoRedirect = true});

  Future<FeeCalculationResponse> calculateFee({
    required int amount,
    required String currency,
    required String cardBin,
    String? token,
    int? merchantId,
  });
}

class CloudipspImpl implements Cloudipsp {
  final int merchantId;
  late CloudipspWebViewHolder _cloudipspWebViewHolder;
  final Api _api;
  final Native _native;
  final PlatformSpecific _platformSpecific;

  CloudipspImpl(this.merchantId, CloudipspWebViewHolder cloudipspWebViewHolder)
      : _api = Api(PlatformSpecific()),
        _native = Native(),
        _platformSpecific = PlatformSpecific() {
    _cloudipspWebViewHolder = cloudipspWebViewHolder;
  }

  CloudipspImpl.withMocks({
    required this.merchantId,
    required CloudipspWebViewHolder cloudipspWebViewHolder,
    required Api api,
    required Native native,
    required PlatformSpecific platformSpecific,
  })  : _api = api,
        _native = native,
        _platformSpecific = platformSpecific,
        _cloudipspWebViewHolder = cloudipspWebViewHolder;

  Future<bool> supportsApplePay() async {
    if (!_platformSpecific.isIOS) {
      return false;
    }
    return _native.supportsApplePay();
  }

  Future<bool> supportsGooglePay() async {
    if (!_platformSpecific.isAndroid) {
      return false;
    }
    return _native.supportsGooglePay();
  }

  _assertApplePay() {
    if (!_platformSpecific.isIOS) {
      throw UnsupportedError('ApplePay available only for iOS');
    }
  }

  _assertGooglePay() {
    if (!_platformSpecific.isAndroid) {
      throw UnsupportedError('GooglePay available only for Android');
    }
  }

  @override
  Future<String> getToken(Order order) {
    return _api.getToken(merchantId, order);
  }

  @override
  Future<Receipt> pay(CreditCard card, Order order) async {
    if (!card.isValid() || !(card is PrivateCreditCard)) {
      throw ArgumentError("CreditCard is not valid");
    }
    final token = await _api.getToken(merchantId, order);
    final checkoutResponse =
        await _api.checkout(card, token, order.email, Api.URL_CALLBACK);
    return _payContinue(checkoutResponse, token, Api.URL_CALLBACK);
  }

  @override
  Future<Receipt> payToken(CreditCard card, String token) async {
    if (!card.isValid() || !(card is PrivateCreditCard)) {
      throw ArgumentError("CreditCard is not valid");
    }
    final order = await _api.getOrder(token);
    final checkoutResponse =
        await _api.checkout(card, token, null, order.responseUrl);
    return await _payContinue(checkoutResponse, token, Api.URL_CALLBACK);
  }

  @override
  Future<Receipt> applePay(Order order) async {
    if (!(merchantId > 0)) {
      throw ArgumentError.value(merchantId, 'merchantId');
    }
    _assertApplePay();
    final config = await _api.getPaymentConfig(
      merchantId: merchantId,
      amount: order.amount,
      currency: order.currency,
      methodId: 'https://apple.com/apple-pay',
      methodName: 'ApplePay',
    );
    dynamic applePayInfo;
    try {
      applePayInfo = await _native.applePay(
          config, order.amount, order.currency, order.description);
    } on PlatformException catch (e) {
      throw CloudipspUserError(e.code, e.message);
    }

    try {
      final token = await _api.getToken(merchantId, order);
      final checkout = await _api.checkoutNativePay(
          token, order.email, config['payment_system'], applePayInfo);
      final receipt = await _payContinue(checkout, token, Api.URL_CALLBACK);
      await _native.applePayComplete(true);
      return receipt;
    } catch (e) {
      _native.applePayComplete(false);
      throw e;
    }
  }

  @override
  Future<Receipt> applePayToken(String token) async {
    _assertApplePay();
    final config = await _api.getPaymentConfig(
      token: token,
      methodId: 'https://apple.com/apple-pay',
      methodName: 'ApplePay',
    );

    final order = await _api.getOrder(token);
    dynamic applePayInfo;
    try {
      applePayInfo =
          await _native.applePay(config, order.amount, order.currency, ' ');
    } on PlatformException catch (e) {
      throw CloudipspUserError(e.code, e.message);
    }

    try {
      final checkout = await _api.checkoutNativePay(
          token, null, config['payment_system'], applePayInfo);
      final receipt = await _payContinue(checkout, token, order.responseUrl);
      await _native.applePayComplete(true);
      return receipt;
    } catch (e) {
      _native.applePayComplete(false);
      throw e;
    }
  }

  @override
  Future<Receipt> googlePay(Order order, dynamic config) async {
    if (!(merchantId > 0)) {
      throw ArgumentError.value(merchantId, 'merchantId');
    }

    _assertGooglePay();

    dynamic googlePayInfo;
    try {
      googlePayInfo = await _native.googlePay(config['data']);
    } on PlatformException catch (e) {
      throw CloudipspUserError(e.code, e.message);
    }

    final token = await _api.getToken(merchantId, order);
    final checkout = await _api.checkoutNativePay(
        token, order.email, config['payment_system'], googlePayInfo);
    return _payContinue(checkout, token, Api.URL_CALLBACK);
  }

  @override
  Future<dynamic> initializePaymentConfig(Order? order, {String? token}) async {
    final config = await _api.getPaymentConfig(
      token: token,
      merchantId: merchantId,
      amount: order?.amount,
      currency: order?.currency,
      methodId: 'https://google.com/pay',
      methodName: 'GooglePay',
    );
    return config;
  }

  @override
  Future<Receipt> googlePayToken(String token, dynamic config) async {
    _assertGooglePay();
    final order = await _api.getOrder(token);
    dynamic googlePayInfo;
    try {
      googlePayInfo = await _native.googlePay(config['data']);
    } on PlatformException catch (e) {
      throw CloudipspUserError(e.code, e.message);
    }

    final checkout = await _api.checkoutNativePay(
        token, null, config['payment_system'], googlePayInfo);
    return _payContinue(checkout, token, order.responseUrl);
  }

  @override
  Future<List<Bank>> getAvailableBankList(Order order) async {
    final token = await _api.getToken(merchantId, order);
    return getAvailableBankListByToken(token);
  }

  @override
  Future<List<Bank>> getAvailableBankListByToken(String token) async {
    try {
      final response = await _api.getAjaxInfo(token);
      List<Bank> banks = [];

      if (response.containsKey('tabs')) {
        final tabs = response['tabs'];
        if (tabs.containsKey('trustly')) {
          final trustly = tabs['trustly'];
          if (trustly.containsKey('payment_systems')) {
            final paymentSystems = trustly['payment_systems'];
            paymentSystems.forEach((key, bankData) {
              if (bankData is Map<String, dynamic>) {
                banks.add(Bank(
                    bankId: key,
                    countryPriority: bankData['country_priority'] ?? 0,
                    userPriority: bankData['user_priority'] ?? 0,
                    quickMethod: bankData['quick_method'] ?? false,
                    userPopular: bankData['user_popular'] ?? false,
                    name: bankData['name'] ?? '',
                    country: bankData['country'] ?? '',
                    bankLogo: bankData['bank_logo'] ?? '',
                    alias: bankData['alias'] ?? ''));
              }
            });
          }
        }
      }

      // Sort banks by user priority and country priority
      banks.sort((bank1, bank2) {
        if (bank1.userPriority != bank2.userPriority) {
          return bank2.userPriority.compareTo(bank1.userPriority);
        }
        return bank2.countryPriority.compareTo(bank1.countryPriority);
      });

      return banks;
    } catch (e) {
      throw CloudipspError(
          'Failed to get available bank list: ${e.toString()}');
    }
  }

  @override
  Future<BankRedirectDetails> initiateBankPayment(Bank bank, Order order,
      {bool autoRedirect = true}) async {
    final token = await _api.getToken(merchantId, order);
    return initiateBankPaymentByToken(token, bank, autoRedirect: autoRedirect);
  }

  @override
  Future<BankRedirectDetails> initiateBankPaymentByToken(
      String token, Bank bank,
      {bool autoRedirect = true}) async {
    try {
      // Get order information
      final receipt = await _api.getAjaxInfo(token);
      final orderData = receipt['order_data'];

      // Create payment request
      final Map<String, dynamic> requestObj = {
        'merchant_id': orderData['merchant_id'],
        'amount': orderData['amount'],
        'currency': orderData['currency'],
        'token': token,
        'payment_system': bank.bankId,
      };

      final response = await _api.callAjax(requestObj);

      final responseStatus = response['response_status'] ?? '';
      final action = response['action'] ?? '';

      if (responseStatus == 'success' &&
          action == 'redirect' &&
          response.containsKey('url')) {
        final redirectUrl = response['url'];
        final target = response['target'] ?? '_top';

        final bankRedirectDetails = BankRedirectDetails(
            action: action,
            url: redirectUrl,
            target: target,
            responseStatus: responseStatus);

        if (autoRedirect) {
          await _launchUrl(redirectUrl);
        }

        return bankRedirectDetails;
      } else {
        throw CloudipspError(
            'Payment initiation failed: payment status: $responseStatus, action: $action');
      }
    } catch (e) {
      throw CloudipspError('Failed to initiate bank payment: ${e.toString()}');
    }
  }

  @override
  Future<FeeCalculationResponse> calculateFee({
    required int amount,
    required String currency,
    required String cardBin,
    String? token,
    int? merchantId,
  }) {
    return _api.calculateFee(
      amount: amount,
      currency: currency,
      cardBin: cardBin,
      token: token,
      merchantId: merchantId ?? this.merchantId,
    );
  }

  Future<bool> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      return await launcher.launchUrl(uri,
          mode: launcher.LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch URL: $url');
    }
  }

  Future<Receipt> _payContinue(
      dynamic checkoutResponse, String token, String callbackUrl) async {
    final url = checkoutResponse['url'] as String;
    if (!url.startsWith(callbackUrl)) {
      final receipt = await _threeDS(url, checkoutResponse, callbackUrl);
      if (receipt != null) {
        return receipt;
      }
    }
    return _api.getOrder(token);
  }

  Future<Receipt?> _threeDS(
      String url, dynamic checkoutResponse, String callbackUrl) async {
    String body;
    String contentType;

    final sendData = checkoutResponse['send_data'] as Map<String, dynamic>;
    if (sendData['PaReq'] == '') {
      body = jsonEncode(sendData);
      contentType = 'application/json';
    } else {
      body = 'MD=' +
          Uri.encodeComponent(sendData['MD']) +
          '&PaReq=' +
          Uri.encodeComponent(sendData['PaReq']) +
          '&TermUrl=' +
          Uri.encodeComponent(sendData['TermUrl']);
      contentType = 'application/x-www-form-urlencoded';
    }

    final response = await _api.call3ds(url, body, contentType);
    final completer = new Completer<Receipt?>();
    _cloudipspWebViewHolder(PrivateCloudipspWebViewConfirmation(
        _native, Api.API_HOST, url, callbackUrl, response, completer));
    return completer.future;
  }
}
