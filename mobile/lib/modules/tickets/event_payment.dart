import 'package:itc_events/modules/tickets/ticket.dart';
import 'package:itc_events/modules/tickets/payment_method.dart';

class EventPayment {
  const EventPayment({
    required this.id,
    required this.eventId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.qrMd5,
    this.merchantName,
    this.qrCode,
    this.abaDeeplink,
    this.method = PaymentMethodOption.khqr,
    this.qrExpiresAt,
    this.paidAt,
    this.ticket,
  });

  final String id;
  final String eventId;
  final String status;
  final double amount;
  final String currency;
  final String qrMd5;
  final String? merchantName;
  final String? qrCode;
  final String? abaDeeplink;
  final String method;
  final DateTime? qrExpiresAt;
  final DateTime? paidAt;
  final Ticket? ticket;

  bool get isPaid => status == 'paid' || ticket != null;
  bool get isPending => status == 'pending';
  bool get isAbaPay => method == PaymentMethodOption.abaPay;
  bool get isExpired {
    if (status == 'expired') return true;
    final expiresAt = qrExpiresAt;
    if (expiresAt == null) return false;
    return !DateTime.now().toUtc().isBefore(expiresAt);
  }

  factory EventPayment.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'];
    return EventPayment(
      id: json['id'].toString(),
      eventId: json['event_id'].toString(),
      status: json['status']?.toString() ?? 'pending',
      amount: _asDouble(json['amount']),
      currency: json['currency'] as String? ?? 'USD',
      qrMd5: json['qr_md5']?.toString() ?? '',
      merchantName: json['merchant_name'] as String?,
      qrCode: json['qr_code'] as String?,
      abaDeeplink: json['aba_deeplink'] as String?,
      method: json['method']?.toString() ?? PaymentMethodOption.khqr,
      qrExpiresAt: _parseOptionalDate(json['qr_expires_at']),
      paidAt: _parseOptionalDate(json['paid_at']),
      ticket: ticketJson is Map<String, dynamic> ? Ticket.fromJson(ticketJson) : null,
    );
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value).toUtc();
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
