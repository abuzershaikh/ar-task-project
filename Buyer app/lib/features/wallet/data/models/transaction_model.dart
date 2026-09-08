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

    TransactionType parseType(String? rawType) {
      final t = (rawType ?? '').toLowerCase().trim();
      if (t == 'credit' || t == 'credits' || t == 'topup' || t == 'deposit') {
        return TransactionType.credit;
      }
      if (t == 'debit' || t == 'debits' || t == 'withdraw' || t == 'order') {
        return TransactionType.debit;
      }
      if (t == 'reserved' || t == 'reserve' || t == 'hold') {
        return TransactionType.reserved;
      }
      if (t == 'captured' || t == 'capture') {
        return TransactionType.captured;
      }
      if (t == 'released' || t == 'release') {
        return TransactionType.released;
      }
      if (t == 'refund') {
        return TransactionType.refund;
      }
      return TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == t,
        orElse: () => TransactionType.credit,
      );
    }

    return TransactionModel(
      id: (json['id'] ?? '').toString(),
      type: parseType(json['type']?.toString()),
      amount: parseD(json['amount']),
      balanceBefore: parseD(json['balanceBefore'] ?? json['balance_before']),
      balanceAfter: parseD(json['balanceAfter'] ?? json['balance_after']),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] ?? '').toString().toLowerCase(),
        orElse: () => TransactionStatus.successful,
      ),
      description: (json['description'] ?? '').toString(),
      referenceId: (json['referenceId'] ?? json['reference_id'])?.toString(),
      referenceType: (json['referenceType'] ?? json['reference_type'])?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
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
