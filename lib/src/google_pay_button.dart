import 'dart:convert';

import 'package:flitt_mobile/flitt_mobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

enum ButtonType {
  book,
  buy,
  checkout,
  donate,
  order,
  pay,
  plain,
  subscribe,
}

enum ButtonThemes { light, dark }

/// Builds a [Cloudipsp] for the button. Injectable for testing; defaults to the
/// real implementation in production.
typedef CloudipspBuilder = Cloudipsp Function(int merchantId,
    void Function(CloudipspWebViewConfirmation) webViewHolder);

/// Renders the official Google Pay button (via the `pay` package's native
/// [RawGooglePayButton], Hybrid Composition) and drives the Flitt payment flow.
///
/// The public API is unchanged from previous versions: the widget takes a
/// [token] or an [order] and reports the result through [onSuccess]/[onError].
/// Only the button rendering was migrated to the `pay` package; the tokenization
/// and 3DS flow still go through [Cloudipsp].
class GooglePayButton extends StatefulWidget {
  final int merchantId;
  final Order? order;
  final void Function(Receipt)? onSuccess;
  final void Function(dynamic error)? onError;
  final VoidCallback? onStart;
  final ButtonThemes theme;
  final ButtonType type;

  /// Desired width. `pay` enforces a minimum width of 168; smaller values are
  /// clamped by the native button.
  final double? width;

  /// Desired height. `pay` renders the button at a fixed height (48); this is
  /// applied via an enclosing [SizedBox].
  final double? height;
  final double? borderRadius;
  final String? token;
  final void Function(CloudipspWebViewConfirmation) webViewHolder;

  /// Test-only seam for injecting a fake [Cloudipsp].
  @visibleForTesting
  final CloudipspBuilder? cloudipspBuilder;

  const GooglePayButton({
    required this.merchantId,
    this.order,
    this.onSuccess,
    this.onError,
    this.onStart,
    this.theme = ButtonThemes.light,
    this.type = ButtonType.pay,
    this.borderRadius,
    this.width,
    this.height,
    this.token,
    required this.webViewHolder,
    this.cloudipspBuilder,
    Key? key,
  }) : super(key: key);

  @override
  _GooglePayButtonState createState() => _GooglePayButtonState();
}

class _GooglePayButtonState extends State<GooglePayButton> {
  late Cloudipsp _cloudipsp;
  Map<String, dynamic>? config;

  @override
  void initState() {
    super.initState();
    _initializeCloudipsp();
  }

  Future<void> _initializeCloudipsp() async {
    _cloudipsp = widget.cloudipspBuilder != null
        ? widget.cloudipspBuilder!(widget.merchantId, widget.webViewHolder)
        : Cloudipsp(widget.merchantId, widget.webViewHolder);
    try {
      final paymentConfig = await _cloudipsp
          .initializePaymentConfig(widget.order, token: widget.token);
      if (!mounted) return;
      setState(() {
        config = paymentConfig;
      });
    } catch (error) {
      widget.onError?.call(error);
    }
  }

  void _onPress() async {
    widget.onStart?.call();
    try {
      final receipt;
      if (widget.token != null) {
        receipt = await _cloudipsp.googlePayToken(widget.token ?? "", config);
      } else {
        receipt = await _cloudipsp.googlePay(widget.order!, config);
      }
      widget.onSuccess?.call(receipt);
    } catch (error) {
      widget.onError?.call(error);
    }
  }

  /// Builds the `pay` [PaymentConfiguration] from the Google Pay object the
  /// Flitt backend already returned (`config['data']`). This stays internal to
  /// the SDK; the merchant only ever supplies a token/order.
  PaymentConfiguration _paymentConfiguration() {
    return PaymentConfiguration.fromJsonString(jsonEncode(<String, dynamic>{
      'provider': 'google_pay',
      'data': config!['data'],
    }));
  }

  GooglePayButtonType _mapType() {
    switch (widget.type) {
      case ButtonType.book:
        return GooglePayButtonType.book;
      case ButtonType.buy:
        return GooglePayButtonType.buy;
      case ButtonType.checkout:
        return GooglePayButtonType.checkout;
      case ButtonType.donate:
        return GooglePayButtonType.donate;
      case ButtonType.order:
        return GooglePayButtonType.order;
      case ButtonType.pay:
        return GooglePayButtonType.pay;
      case ButtonType.plain:
        return GooglePayButtonType.plain;
      case ButtonType.subscribe:
        return GooglePayButtonType.subscribe;
    }
  }

  GooglePayButtonTheme _mapTheme() {
    return widget.theme == ButtonThemes.dark
        ? GooglePayButtonTheme.dark
        : GooglePayButtonTheme.light;
  }

  @override
  Widget build(BuildContext context) {
    // Render only once the payment configuration is loaded. RawGooglePayButton
    // itself gates on Google Pay availability, so a single async source remains
    // and the previous create-before-config race is gone.
    if (config == null) {
      return const SizedBox.shrink();
    }

    Widget button = RawGooglePayButton(
      paymentConfiguration: _paymentConfiguration(),
      type: _mapType(),
      theme: _mapTheme(),
      cornerRadius: widget.borderRadius?.round() ?? 24,
      onPressed: _onPress,
    );

    if (widget.width != null || widget.height != null) {
      button = SizedBox(
        width: widget.width,
        height: widget.height,
        child: button,
      );
    }
    return button;
  }
}
