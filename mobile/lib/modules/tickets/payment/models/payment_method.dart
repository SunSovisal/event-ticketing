class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    this.live = false,
    this.sandbox = false,
  });

  static const khqr = 'khqr';
  static const abaPay = 'aba_pay';

  final String id;
  final bool live;
  final bool sandbox;

  bool get isKhqr => id == khqr;
  bool get isAbaPay => id == abaPay;

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) {
    return PaymentMethodOption(
      id: json['id']?.toString() ?? '',
      live: json['live'] == true,
      sandbox: json['sandbox'] == true,
    );
  }
}
