import '../../domain/entities/transaction.dart';

// @JsonSerializable() - Commented for build
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.balanceBefore,
    required super.balanceAfter,
    required super.status,
    required super.description,
    super.referenceId,
    super.referenceType,
    required super.createdAt,
    super.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return TransactionModel(
      id: (json['id'] ?? '').toString(),
      type: TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['type'] ?? '').toString().toLowerCase(),
        orElse: () => TransactionType.credit,
      ),
      amount: parseD(json['amount']),
      balanceBefore: parseD(json['balanceBefore']),
      balanceAfter: parseD(json['balanceAfter']),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] ?? '').toString().toLowerCase(),
        orElse: () => TransactionStatus.successful,
      ),
      description: (json['description'] ?? '').toString(),
      referenceId: json['referenceId']?.toString(),
      referenceType: json['referenceType']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'status': status.toString().split('.').last,
      'description': description,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      id: entity.id,
      type: entity.type,
      amount: entity.amount,
      balanceBefore: entity.balanceBefore,
      balanceAfter: entity.balanceAfter,
      status: entity.status,
      description: entity.description,
      referenceId: entity.referenceId,
      referenceType: entity.referenceType,
      createdAt: entity.createdAt,
      metadata: entity.metadata,
    );
  }

  Transaction toEntity() {
    return Transaction(
      id: id,
      type: type,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      status: status,
      description: description,
      referenceId: referenceId,
      referenceType: referenceType,
      createdAt: createdAt,
      metadata: metadata,
    );
  }
}
