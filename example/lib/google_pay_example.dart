import 'package:flutter/material.dart';
import 'package:flitt_mobile/flitt_mobile.dart';

/// A minimal, self-contained Google Pay example.
///
/// Copy this widget into your app and change [_merchantId] and the [Order]
/// details. The Google Pay button renders only on Android where Google Pay is
/// available; on other platforms it shows nothing.
class GooglePayExample extends StatefulWidget {
  const GooglePayExample({Key? key}) : super(key: key);

  @override
  State<GooglePayExample> createState() => _GooglePayExampleState();
}

class _GooglePayExampleState extends State<GooglePayExample> {
  // Your Flitt merchant id.
  static const int _merchantId = 1549901;

  // The order to charge. Created once so its id stays stable for this purchase.
  late final Order _order = Order(
    100, // amount in the smallest currency unit: 100 => 1.00
    'GEL',
    'Flutter_${DateTime.now().millisecondsSinceEpoch}',
    'Test payment',
    'example@test.com',
  );

  final GlobalKey _webViewKey = GlobalKey();

  // Set while the 3-D Secure confirmation web view needs to be shown.
  CloudipspWebViewConfirmation? _confirmation;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Google Pay')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pay 1.00 GEL with Google Pay:'),
                const SizedBox(height: 16.0),
                // SizedBox(width: infinity) makes the button fill the width;
                // the native Google Pay button then renders full-width.
                SizedBox(
                  width: double.infinity,
                  child: GooglePayButton(
                    merchantId: _merchantId,
                    order: _order,
                    webViewHolder: (confirmation) =>
                        setState(() => _confirmation = confirmation),
                    onSuccess: (receipt) {
                      setState(() => _confirmation = null);
                      _showMessage(
                          'Paid ${receipt.status}, id ${receipt.paymentId}');
                    },
                    onError: (error) {
                      setState(() => _confirmation = null);
                      _showMessage('Google Pay error: $error');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Show the 3-D Secure confirmation as a full-screen popup that covers
        // the whole screen (including the app bar), inside the safe area.
        if (_confirmation != null)
          Positioned.fill(
            child: Material(
              child: SafeArea(
                child: CloudipspWebView(
                  key: _webViewKey,
                  confirmation: _confirmation!,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
