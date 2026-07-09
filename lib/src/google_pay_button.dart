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
    return supportsGPay && config != null
        ? AndroidView(
            key: _viewKey,
            viewType: 'google_pay_button_view',
            creationParams: <String, dynamic>{
              'allowedPaymentMethods': config?['data']
                  ?['allowedPaymentMethods'],
              'theme': widget.theme.toString().split('.').last,
              'type': widget.type.toString().split('.').last,
              'borderRadius': widget.borderRadius,
              'width': widget.width,
              'height': widget.height,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: (int id) {
              _channel.setMethodCallHandler((call) async {
                if (call.method == 'onPress') {
                  _onPress();
                }
              });
            },
          )
        : Container();
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
