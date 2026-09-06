class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final double amount;
  final String currency;
  final String status;
  final String downloadUrl;
  final DateTime date;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.currency,
    required this.status,
    required this.downloadUrl,
    required this.date,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return InvoiceModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? json['number'] ?? 'INV-001').toString(),
      amount: parseD(json['amount']),
      currency: (json['currency'] ?? 'INR').toString(),
      status: (json['status'] ?? 'PAID').toString(),
      downloadUrl: (json['downloadUrl'] ?? json['pdfUrl'] ?? '').toString(),
      date: json['createdAt'] != null || json['date'] != null
          ? DateTime.tryParse((json['createdAt'] ?? json['date']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
