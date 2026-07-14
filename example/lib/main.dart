import 'example.dart';
import 'google_pay_example.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Cloudipsp Flutter SDK Example'),
          ),
          body: Example(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GooglePayExample(),
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Google Pay example'),
          ),
        ),
      ),
    );
  }
}
