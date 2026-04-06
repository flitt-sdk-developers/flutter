class FeeCalculationResponse {
  final num? discountPercent;
  final num? discountAmount;
  final num? feeAmount;
  final num? totalAmount;
  final String? promoStatus;
  final String? message;
  final String? cvv2Requirement; 

  FeeCalculationResponse({
    required this.discountPercent,
    required this.discountAmount,
    required this.feeAmount,
    required this.totalAmount,
    required this.promoStatus,
    required this.message,
    required this.cvv2Requirement,
  });

  factory FeeCalculationResponse.fromJson(Map<String, dynamic> json) {
    return FeeCalculationResponse(
      discountPercent: json['discount_percent'],
      discountAmount: json['discount_amount'],
      feeAmount: json['fee_amount'],
      totalAmount: json['total_amount'],
      promoStatus: json['promo_status'],
      message: json['message'],
      cvv2Requirement: json['cvv2_requirement'],
    );
  }
}

