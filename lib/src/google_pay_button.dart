import 'package:flitt_mobile/flitt_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Standard Google Pay button height in logical pixels (dp). Also used as the
/// minimum so the button always meets Google's brand guidelines and never
/// renders as a thin strip.
const double _kGooglePayButtonHeight = 48.0;

class GooglePayButton extends StatefulWidget {
  final int merchantId;
  final Order? order;
  final void Function(Receipt)? onSuccess;
  final void Function(dynamic error)? onError;
  final VoidCallback? onStart;
  final ButtonThemes theme;
  final ButtonType type;
  final double? width;
  final double? height;
  final double? borderRadius;
  final String? token;
  final void Function(CloudipspWebViewConfirmation) webViewHolder;

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
    Key? key,
  }) : super(key: key);

  @override
  _GooglePayButtonState createState() => _GooglePayButtonState();
}

class _GooglePayButtonState extends State<GooglePayButton> {
  static const MethodChannel _channel = MethodChannel('google_pay_button');
  late Cloudipsp _cloudipsp;
  bool supportsGPay = false;
  Map<String, dynamic>? config;
  UniqueKey _viewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeCloudipsp();
    _checkGPaySupport();
  }

  Future<void> _initializeCloudipsp() async {
    _cloudipsp = Cloudipsp(widget.merchantId, widget.webViewHolder);
    try {
      final paymentConfig = await _cloudipsp
          .initializePaymentConfig(widget.order, token: widget.token);
      setState(() {
        config = paymentConfig;
      });
    } catch (error) {
      widget.onError?.call(error);
    }
  }

  Future<void> _checkGPaySupport() async {
    try {
      supportsGPay = await _cloudipsp.supportsGooglePay();
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    if (!(supportsGPay && config != null)) {
      return Container();
    }
    // The native PayButton has a fixed height, but an AndroidView fills the
    // constraints it is given and would take infinite height inside a Column /
    // ScrollView. Bound it here (respecting an explicit height, else the
    // standard Google Pay button height).
    //
    // Google's brand guidelines require the button to keep its proportions and
    // be at least as prominent as other buttons, so clamp to a 48dp minimum
    // (the standard Google Pay button height) even if a smaller height is
    // requested — otherwise the button renders as a narrow strip.
    // https://developers.google.com/pay/api/web/guides/brand-guidelines
    final double effectiveHeight =
        (widget.height ?? _kGooglePayButtonHeight).clamp(
      _kGooglePayButtonHeight,
      double.infinity,
    );
    return SizedBox(
      width: widget.width,
      height: effectiveHeight,
      child: AndroidView(
        key: _viewKey,
        viewType: 'google_pay_button_view',
        creationParams: <String, dynamic>{
          'allowedPaymentMethods': config?['data']?['allowedPaymentMethods'],
          'theme': widget.theme.toString().split('.').last,
          'type': widget.type.toString().split('.').last,
          'borderRadius': widget.borderRadius,
          'width': widget.width,
          'height': effectiveHeight,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          _channel.setMethodCallHandler((call) async {
            if (call.method == 'onPress') {
              _onPress();
            }
          });
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant GooglePayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.width != oldWidget.width ||
        widget.height != oldWidget.height ||
        widget.theme != oldWidget.theme ||
        widget.type != oldWidget.type ||
        widget.borderRadius != oldWidget.borderRadius) {
      setState(() {
        _viewKey = UniqueKey();
      });
    }
  }
}
