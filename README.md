# Flitt Flutter SDK Integration Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Basic Setup](#basic-setup)
4. [Google Pay Button Implementation](#google-pay-button-implementation)
5. [Payment Methods](#payment-methods)
6. [Button Customization](#button-customization)
7. [Handling Payment Results](#handling-payment-results)
8. [WebView Integration](#webview-integration)
9. [Complete Parameters Reference](#complete-parameters-reference)
10. [Examples](#examples)
11. [Payment with bank](#Payment-with-bank)
12. [Troubleshooting](#troubleshooting)

## Introduction

The Flitt Flutter SDK enables seamless integration of payment processing capabilities into your Flutter applications. This document focuses on the implementation of Google Pay functionality using the Flitt Flutter SDK.

## Installation

Add the Flitt SDK to your Flutter project by adding the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
   flitt_mobile: ^2.0.0
```

Then run:

```bash
flutter pub get
```

## Basic Setup

Import the Flitt package in your Dart file:

```dart
import 'package:flitt_mobile/flitt_mobile.dart';
import 'package:flutter/material.dart';
```

## Google Pay Button Implementation

The SDK provides a `GooglePayButton` widget that you can add to your Flutter UI to enable Google Pay payments:

```dart
// Create a WebView confirmation handler
void handleWebViewConfirmation(CloudipspWebViewConfirmation confirmation) {
  // Handle the WebView confirmation
}

// Add the Google Pay button to your UI
GooglePayButton(
  merchantId: 1234567,  // Your merchant ID
  order: createOrder(),  // For order-based payments
  // token: "your_payment_token",  // For token-based payments
  webViewHolder: handleWebViewConfirmation,
  onSuccess: (Receipt receipt) {
    // Handle successful payment
    print("Payment successful: ${receipt.paymentId}");
  },
  onError: (dynamic error) {
    // Handle payment error
    print("Payment error: $error");
  },
  onStart: () {
    // Handle payment start
    print("Payment started");
  },
)
```

## Payment Methods

The Flitt Flutter SDK supports two different payment methods:

### 1. Token-Based Payment

Use a pre-generated token from your backend:

```dart
GooglePayButton(
  merchantId: 1234567,
  token: "your_payment_token",  // Provide the token string
  webViewHolder: handleWebViewConfirmation,
  // Other parameters...
)
```

This approach is useful when:
- You have a pre-generated token from your server
- The payment amount and details are already defined on the server side
- You want to simplify the client-side implementation

### 2. Order-Based Payment

Create an Order object for more control over payment details:

```dart
// Create an order
Order createOrder() {
  return Order(
    amount: 100,              // Amount in smallest currency unit (e.g., cents)
    currency: "USD",          // Currency code
    orderId: "order_${DateTime.now().millisecondsSinceEpoch}",  // Unique order ID
    description: "Test payment",  // Payment description
    email: "customer@example.com",  // Customer email
  );
}

// Use the order with the button
GooglePayButton(
  merchantId: 1234567,
  order: createOrder(),  // Provide the order object
  webViewHolder: handleWebViewConfirmation,
  // Other parameters...
)
```

This approach is beneficial when:
- You need to dynamically set the payment amount in the app
- You want to include specific customer information
- You need to generate order IDs client-side
- You require more detailed control over the payment parameters

**Important Note**: You should use either `token` or `order`, but not both simultaneously.

## Button Customization

The Google Pay button can be extensively customized to match your app's design:

### Button Type

The SDK provides various button label types through the `ButtonType` enum:

```dart
GooglePayButton(
  // Required parameters...
  type: ButtonType.buy,  // Options: book, buy, checkout, donate, order, pay, plain, subscribe
  // Other parameters...
)
```

### Button Theme

Choose between light and dark themes:

```dart
GooglePayButton(
  // Required parameters...
  theme: ButtonThemes.dark,  // Options: light, dark
  // Other parameters...
)
```

### Button Size

Customize the button dimensions:

```dart
GooglePayButton(
  // Required parameters...
  width: 300,    // Width in logical pixels
  height: 48,    // Height in logical pixels
  // Other parameters...
)
```

### Button Border Radius

Customize the button's corner roundness:

```dart
GooglePayButton(
  // Required parameters...
  borderRadius: 8.0,  // Corner radius in logical pixels
  // Other parameters...
)
```

## Handling Payment Results

### Success Callback

```dart
GooglePayButton(
  // Required parameters...
  onSuccess: (Receipt receipt) {
    // Access receipt properties
    String paymentId = receipt.paymentId;
    String status = receipt.status.name;
    
    // Update UI or navigate to success screen
    Navigator.pushNamed(context, '/success', arguments: receipt);
  },
  // Other parameters...
)
```

### Error Callback

```dart
GooglePayButton(
  // Required parameters...
  onError: (dynamic error) {
    // Handle different error types
    String errorMessage = "Payment failed";
    
    if (error is CloudipspException) {
      errorMessage = error.message;
      // Handle specific error types
    }
    
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage))
    );
  },
  // Other parameters...
)
```

### Start Callback

```dart
GooglePayButton(
  // Required parameters...
  onStart: () {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
  },
  // Other parameters...
)
```

## WebView Integration

The SDK requires a WebView integration for handling payment confirmation. You need to implement a handler function for the `webViewHolder` parameter.

There are two main approaches to implementing the WebView integration:

### 1. Using the Built-in CloudipspWebView

The simplest approach is to use the built-in `CloudipspWebView` component provided by the SDK:

```dart
import 'package:flitt_mobile/src/cloudipsp_web_view_confirmation.dart';

void webViewHolder(CloudipspWebViewConfirmation confirmation) {
  if (confirmation is PrivateCloudipspWebViewConfirmation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CloudipspWebView(
          key: UniqueKey(),
          confirmation: confirmation,
        ),
      ),
    );
  }
}
```

This approach:
- Uses the SDK's pre-built WebView component
- Handles all necessary callbacks automatically
- Opens the WebView in a new screen using Navigator

### 2. Custom WebView Implementation

For more control over the UI, you can create a custom implementation:

```dart
void handleWebViewConfirmation(CloudipspWebViewConfirmation confirmation) {
  // Show the WebView for 3DS authentication or other confirmation steps
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: Text('Payment Confirmation'),
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  confirmation.cancel();
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: confirmation.webView,
            ),
          ],
        ),
      );
    },
  );
}
```

This approach:
- Allows customization of the WebView container
- Can be shown in a bottom sheet or dialog
- Gives you control over navigation and UI elements

## Complete Parameters Reference

### GooglePayButton Widget Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| merchantId | `int` | Yes | Your Flitt merchant account ID |
| webViewHolder | `Function(CloudipspWebViewConfirmation)` | Yes | Function to handle WebView confirmation display |
| order | `Order?` | Yes* | Payment order details (*required if not using token) |
| token | `String?` | Yes* | Pre-generated payment token (*required if not using order) |
| onSuccess | `Function(Receipt)?` | No | Callback for successful payment |
| onError | `Function(dynamic)?` | No | Callback for payment errors |
| onStart | `VoidCallback?` | No | Callback when payment process starts |
| theme | `ButtonThemes` | No | Visual theme - default is `ButtonThemes.light` |
| type | `ButtonType` | No | Button label type - default is `ButtonType.pay` |
| width | `double?` | No | Button width in logical pixels |
| height | `double?` | No | Button height in logical pixels |
| borderRadius | `double?` | No | Button corner radius in logical pixels |

### Order Parameters

When creating an Order object, you need to set the following parameters:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| amount | `int` | Yes | Payment amount in the smallest currency unit (e.g., cents) |
| currency | `String` | Yes | Three-letter currency code (e.g., "USD", "EUR") |
| orderId | `String` | Yes | Unique identifier for the order |
| description | `String` | Yes | Payment description |
| email | `String` | Yes | Customer email address |

### ButtonType Enum Values

| Value | Description |
|-------|-------------|
| book | "Book with Google Pay" button |
| buy | "Buy with Google Pay" button |
| checkout | "Checkout with Google Pay" button |
| donate | "Donate with Google Pay" button |
| order | "Order with Google Pay" button |
| pay | "Pay with Google Pay" button |
| plain | Google Pay logo only (no text) |
| subscribe | "Subscribe with Google Pay" button |

### ButtonThemes Enum Values

| Value | Description |
|-------|-------------|
| light | Light theme (black text on white background) |
| dark | Dark theme (white text on black background) |

## Examples

### Complete Implementation Example

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flitt_mobile/flitt_mobile.dart';
import 'package:flitt_mobile/src/cloudipsp_web_view_confirmation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flitt Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GPay(),
    );
  }
}

class GPay extends StatefulWidget {
  @override
  _GPay createState() => _GPay();
}

class _GPay extends State<GPay> {
  // Your merchant ID from Flitt
  int merchantId = 1549901;

  // WebView handler for payment confirmation
  void webViewHolder(CloudipspWebViewConfirmation confirmation) {
    if (confirmation is PrivateCloudipspWebViewConfirmation) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CloudipspWebView(
            key: UniqueKey(),
            confirmation: confirmation,
          ),
        ),
      );
    }
  }

  // Helper function to display alert dialogs
  void _showAlertDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Pay Button Example'),
      ),
      body: Center(
        child: GooglePayButton(
          // Required parameters
          merchantId: merchantId,
          webViewHolder: webViewHolder,
          
          // Token-based payment (using a pre-generated token)
          token: "4facc45f577adbebea13cb95af0c8e833b9cec0a",
          
          // Alternative: Order-based payment
          // order: Order(
          //   1000,
          //   'GEL',
          //   DateTime.now().toString(),
          //   'Test payment',
          //   'customer@example.com',
          // ),
          
          // Appearance customization
          type: ButtonType.pay,
          theme: ButtonThemes.dark,
          borderRadius: 30,
          // width: 700,
          // height: 240,
          
          // Callback handlers
          onSuccess: (Receipt receipt) {
            Navigator.of(context).pop();
            _showAlertDialog(context, "Success: ", receipt.approvalCode);
          },
          onError: (error) {
            _showAlertDialog(context, "Error: ", error?.message);
          },
          onStart: () {
            // Optional: Show loading indicator or perform other actions
          },
        ),
      ),
    );
  }
}
```
## Payment with bank

### Loading Available Banks with token

```dart
Future<void> _loadBanks() async {
  try {
    final banks = await _cloudipsp.getAvailableBankListByToken(
      "your_payment_token"
    );
    // Process the list of available banks
  } catch (e) {
    // Handle error
  }
}
```
### Loading Available Banks with order

### Creating an Order

```dart
Order _createOrder() {
  return Order(
    100, // Amount in the smallest currency unit (cents/pennies)
    'GEL', // Currency code
    'unique_order_id', 
    'Payment Description',
    'customer@example.com'
  );
}
```
```dart
Future<void> _loadBanks() async {
  try {
    final order = _createOrder();
    final banks = await _cloudipsp.getAvailableBankList(order);
    // Process the list of available banks
  } catch (e) {
    // Handle error
  }
}
```

### Card fee calculation (calc_v2) + CVV requirement

Use this when you want to calculate card fees **before** charging the card and hide CVV if it’s not required (`cvv2_requirement == "absent"`).

```dart
CreditCardInputView(
  helperNeeded: kDebugMode,
  inputDecoration: const InputDecoration(border: OutlineInputBorder()),
  merchantId: 4055775,
  amount: 1, // smallest currency unit
  currency: 'UZS',
  // token: '...', // optional (for token-based flow)
  onFeeResult: (FeeCalculationResponse fee) {
    // fee.feeAmount, fee.totalAmount, fee.cvv2Requirement, ...
  },
)
```

Notes:
- The SDK requests fees from `api/fee/calc_v2` once card number length is **>= 6**.
- If `cvv2_requirement` is `"absent"`, the CVV field is hidden and `cvv2` is **not sent** in the checkout request.

### Custom fee calculation (no UI)

If you have your own card form, you can call fee calculation directly:

```dart
final cloudipsp = Cloudipsp(
  4055775,
  (_) {}, // WebView holder (not used for fee calculation)
);

final fee = await cloudipsp.calculateFee(
  amount: 1,
  currency: 'UZS',
  cardBin: '8600202020202023', 
  // token: '...', // optional
);

print('fee=${fee.feeAmount}, total=${fee.totalAmount}, cvv2=${fee.cvv2Requirement}');
```


```dart
Future<void> _loadBanks() async {
  try {
    final order = _createOrder();
    final banks = await _cloudipsp.getAvailableBankListByToken(
      "your_payment_token"
    );
    // Process the list of available banks
  } catch (e) {
    // Handle error
  }
}
```



### Initiating Bank Payment

```dart
Future<void> _initiateBankPayment(Bank bank) async {
  try {
    final order = _createOrder();
    final redirectDetails = await _cloudipsp.initiateBankPaymentByToken(
      "your_payment_token",
      bank,
      autoRedirect: false // Set to true for automatic redirection
    );
    
    // Manually launch payment URL if autoRedirect is false
    if (!await launchUrl(Uri.parse(redirectDetails.url))) {
      throw Exception('Could not launch payment URL');
    }
  } catch (e) {
    // Handle payment initiation error
  }
}
```

## Parameters and Configuration

### Bank Payment Initiation Parameters
- `paymentToken`: Secure token for payment processing
- `bank`: Selected bank object
- `autoRedirect`:
   - `true`: Automatically open bank's payment page
   - `false`: Manually handle redirection


## Bank List Response Parameters

The `getAvailableBankListByToken` method returns a `BankRedirectDetails` object with the following parameters:

- `url`: Secure token for payment processing
- `action`: redirect
- `responseStatus`: success | failed
- `target`: _top | _blank | _self


### Sample Full Response
```json
{
  "action": "redirect",
  "url": "https://main.d2u132ejo2851c.amplifyapp.com/login/?state=cDozNDI=&amount=2.0&description=merchant:%20Test%20merchant%20|%20100015008%20|",
  "target": "_top",
  "response_status": "success"
}
```



### Additional Utility Methods
- `isQuickMethod()`: Returns whether it's a quick payment method
- `isUserPopular()`: Returns whether the bank is user-popular
- Corresponding getter methods for each property (e.g., `getBankId()`, `getName()`)


## Troubleshooting

### Common Issues

1. **Google Pay button doesn't appear**
   - Ensure Google Pay is available on the device
   - Verify your merchant ID is correct
   - Check that the device supports Google Pay

2. **Payment failure**
   - Verify internet connection
   - Check that all payment details are correctly formatted
   - Ensure you're using either token OR order, not both

3. **WebView doesn't display**
   - Ensure your webViewHolder function is correctly implemented
   - Check that the WebView is being added to the widget tree

### Debugging Tips

- Use the onError callback to log detailed error information
- Check the Flitt dashboard for transaction status
- Test on actual devices, not just emulators
- Ensure you have the latest version of the SDK

## Conclusion

The Flitt Flutter SDK provides a robust solution for integrating Google Pay payments into your Flutter applications. By following this documentation, you should be able to successfully implement and customize the Google Pay button in your app.

For more information, refer to the official Flitt documentation or contact their support team.
