import 'package:flitt_mobile/flitt_mobile.dart';
import 'package:flutter/material.dart';

import './credit_card_input_layout.dart';
import './fee_calculation_response.dart';
import './api.dart';
import './platform_specific.dart';

class CreditCardInputView extends StatefulWidget {
  final bool _helperNeeded;
  final InputDecoration? _inputNumberDecoration;
  final InputDecoration? _inputExpMmDecoration;
  final InputDecoration? _inputExpYyDecoration;
  final InputDecoration? _inputCvvDecoration;
  final InputDecoration? _inputDecoration;
  final int? _amount;
  final String? _currency;
  final int? _merchantId;
  final String? _token;
  final void Function(FeeCalculationResponse response)? _onFeeResult;

  CreditCardInputView(
      {Key? key,
      bool helperNeeded = false,
      InputDecoration? inputNumberDecoration,
      InputDecoration? inputExpMmDecoration,
      InputDecoration? inputExpYyDecoration,
      InputDecoration? inputCvvDecoration,
      InputDecoration? inputDecoration,
      int? amount,
      String? currency,
      int? merchantId,
      String? token,
      void Function(FeeCalculationResponse response)? onFeeResult})
      : _helperNeeded = helperNeeded,
        _inputNumberDecoration = inputNumberDecoration,
        _inputExpMmDecoration = inputExpMmDecoration,
        _inputExpYyDecoration = inputExpYyDecoration,
        _inputCvvDecoration = inputCvvDecoration,
        _inputDecoration = inputDecoration,
        _amount = amount,
        _currency = currency,
        _merchantId = merchantId,
        _token = token,
        _onFeeResult = onFeeResult,
        super(key: key);

  @override
  CreditCardInputViewState createState() {
    return CreditCardInputViewState(
        helperNeeded: _helperNeeded,
        inputNumberDecoration: _inputNumberDecoration,
        inputExpMmDecoration: _inputExpMmDecoration,
        inputExpYyDecoration: _inputExpYyDecoration,
        inputCvvDecoration: _inputCvvDecoration,
        inputDecoration: _inputDecoration);
  }
}

class CreditCardInputViewState extends State<CreditCardInputView>
    implements CreditCardInputState {
  static const _HELP_CARDS = [
    '4444555566661111',
    '4444111166665555',
    '4444555511116666',
    '4444111155556666'
  ];

  final bool _helperNeeded;
  final InputDecoration? _inputNumberDecoration;
  final InputDecoration? _inputExpMmDecoration;
  final InputDecoration? _inputExpYyDecoration;
  final InputDecoration? _inputCvvDecoration;
  final InputDecoration? _inputDecoration;
  final GlobalKey _creditCardInputLayoutKey = GlobalKey();
  final GlobalKey<_CreditCardCvvSectionState> _cvvSectionKey =
      GlobalKey<_CreditCardCvvSectionState>();

  int _currentHelpCardIndex = 0;
  String? _cvv2Requirement;
  String? _lastBin;
  final Api _api = Api(PlatformSpecific());
  VoidCallback? _cardNumberListener;

  CreditCardInputViewState(
      {bool helperNeeded = false,
      InputDecoration? inputNumberDecoration,
      InputDecoration? inputExpMmDecoration,
      InputDecoration? inputExpYyDecoration,
      InputDecoration? inputCvvDecoration,
      InputDecoration? inputDecoration})
      : _helperNeeded = helperNeeded,
        _inputNumberDecoration = inputNumberDecoration,
        _inputExpMmDecoration = inputExpMmDecoration,
        _inputExpYyDecoration = inputExpYyDecoration,
        _inputCvvDecoration = inputCvvDecoration,
        _inputDecoration = inputDecoration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachCardNumberListener();
    });
  }

  @override
  void didUpdateWidget(covariant CreditCardInputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._amount != widget._amount ||
        oldWidget._currency != widget._currency) {
      final lastBin = _lastBin;
      if (lastBin != null) {
        _fetchCardFee(lastBin);
      }
    }
  }

  @override
  void dispose() {
    _detachCardNumberListener();
    super.dispose();
  }

  @override
  CreditCard getCard() {
    if (_creditCardInputLayoutKey.currentState == null) {
      throw StateError("CreditCardInputView hasn't been rendered yet");
    }
    final creditCardInputLayoutState =
        _creditCardInputLayoutKey.currentState as CreditCardInputLayoutState;
    return creditCardInputLayoutState.getCard();
  }

  void _attachCardNumberListener() {
    if (_creditCardInputLayoutKey.currentState == null) {
      return;
    }
    final creditCardInputLayoutState =
        _creditCardInputLayoutKey.currentState as CreditCardInputLayoutState;
    _detachCardNumberListener();
    _cardNumberListener = () {
      _onCardNumberChanged(creditCardInputLayoutState.cardNumberController.text);
    };
    creditCardInputLayoutState.cardNumberController.addListener(_cardNumberListener!);
  }

  void _detachCardNumberListener() {
    if (_creditCardInputLayoutKey.currentState == null || _cardNumberListener == null) {
      _cardNumberListener = null;
      return;
    }
    final creditCardInputLayoutState =
        _creditCardInputLayoutKey.currentState as CreditCardInputLayoutState;
    creditCardInputLayoutState.cardNumberController.removeListener(_cardNumberListener!);
    _cardNumberListener = null;
  }

  Future<void> _fetchCardFee(String cardBin) async {
    final amount = widget._amount;
    final currency = widget._currency;
    final merchantId = widget._merchantId;
    if (amount == null || currency == null || merchantId == null) {
      return;
    }
    try {
      final response = await _api.calculateFee(
        amount: amount,
        currency: currency,
        cardBin: cardBin,
        merchantId: merchantId,
        token: widget._token,
      );
      if (!mounted) return;
      setState(() {
        _cvv2Requirement = response.cvv2Requirement;
      });
      _cvvSectionKey.currentState
          ?.setVisible((_cvv2Requirement ?? '').trim().toLowerCase() != 'absent');
      final creditCardInputLayoutState =
          _creditCardInputLayoutKey.currentState as CreditCardInputLayoutState?;
      creditCardInputLayoutState?.setCvv2Requirement(_cvv2Requirement);
      widget._onFeeResult?.call(response);
    } catch (e) {
      // ignore fee calc errors
    }
  }

  void _onCardNumberChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s+'), '');
    if (digits.length >= 6) {
      final cardBin = digits;
      if (cardBin != _lastBin) {
        _lastBin = cardBin;
        _fetchCardFee(cardBin);
      }
    } else if (digits.length < 6) {
      _lastBin = null;
      if (_cvv2Requirement != null) {
        setState(() {
          _cvv2Requirement = null;
        });
        _cvvSectionKey.currentState?.setVisible(true);
        final creditCardInputLayoutState =
            _creditCardInputLayoutKey.currentState as CreditCardInputLayoutState?;
        creditCardInputLayoutState?.setCvv2Requirement(null);
      }
    }
  }

  void _nextHelpCard() {
    final creditCardInputLayoutState =
        _creditCardInputLayoutKey.currentState as CreditCardInputLayoutState;

    _currentHelpCardIndex %= _HELP_CARDS.length;
    creditCardInputLayoutState.setHelpCard(
        _HELP_CARDS[_currentHelpCardIndex++], '12', '29', '111');
  }

  @override
  Widget build(BuildContext context) {
    Widget cardNumberLabel =
        Text('CardNumber:', textDirection: TextDirection.ltr);
    if (_helperNeeded) {
      cardNumberLabel = GestureDetector(
        onTap: _nextHelpCard,
        child: cardNumberLabel,
      );
    }

    return CreditCardInputLayout(
        key: _creditCardInputLayoutKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cardNumberLabel,
            CreditCardNumberField(
                decoration: _oneOf(_inputNumberDecoration, _inputDecoration)),
            SizedBox(
              height: 15.0,
            ),
            Row(
              children: [
                Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exp. Year', textDirection: TextDirection.ltr),
                        CreditCardExpYyField(
                            decoration: _oneOf(
                                _inputExpYyDecoration, _inputDecoration)),
                      ],
                    )),
                SizedBox(
                  width: 15.0,
                ),
                Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exp. Month', textDirection: TextDirection.ltr),
                        CreditCardExpMmField(
                            decoration: _oneOf(
                                _inputExpMmDecoration, _inputDecoration)),
                      ],
                    )),
              ],
            ),
            SizedBox(
              height: 15.0,
            ),
            _CreditCardCvvSection(
              key: _cvvSectionKey,
              decoration: _oneOf(_inputCvvDecoration, _inputDecoration),
            ),
          ],
        ));
  }

  static InputDecoration? _oneOf(
      InputDecoration? main, InputDecoration? alternative) {
    if (main != null) {
      return main;
    }
    return alternative;
  }
}

class _CreditCardCvvSection extends StatefulWidget {
  final InputDecoration? decoration;

  const _CreditCardCvvSection({Key? key, this.decoration}) : super(key: key);

  @override
  State<_CreditCardCvvSection> createState() => _CreditCardCvvSectionState();
}

class _CreditCardCvvSectionState extends State<_CreditCardCvvSection> {
  bool _visible = true;

  void setVisible(bool visible) {
    if (_visible == visible) return;
    setState(() {
      _visible = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cvv:', textDirection: TextDirection.ltr),
        CreditCardCvvField(decoration: widget.decoration),
      ],
    );
  }
}
