import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pay/pay.dart';

import 'package:flitt_mobile/flitt_mobile.dart';
import 'package:flitt_mobile/src/cloudipsp.dart';

/// Minimal fake so we can drive config loading without touching the network or
/// platform channels. Only the member the widget uses is implemented.
class _FakeCloudipsp implements Cloudipsp {
  _FakeCloudipsp(this._config);

  final Future<dynamic> _config;

  @override
  int get merchantId => 1;

  @override
  Future<dynamic> initializePaymentConfig(Order? order, {String? token}) =>
      _config;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  Widget buildButton(_FakeCloudipsp fake) => MaterialApp(
        home: Scaffold(
          body: GooglePayButton(
            merchantId: 1,
            token: 'tok',
            webViewHolder: (_) {},
            cloudipspBuilder: (_, __) => fake,
          ),
        ),
      );

  testWidgets('renders nothing while the payment config is still loading',
      (tester) async {
    // Config never resolves during the test — the button must not be built.
    final fake = _FakeCloudipsp(Completer<dynamic>().future);

    await tester.pumpWidget(buildButton(fake));
    await tester.pump();

    expect(find.byType(RawGooglePayButton), findsNothing);
    expect(find.byType(SizedBox), findsWidgets); // SizedBox.shrink placeholder
  });
}
