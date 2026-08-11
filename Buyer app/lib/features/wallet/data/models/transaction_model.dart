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
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.credit,
      ),
      amount: (json['amount'] as num).toDouble(),
      balanceBefore: (json['balanceBefore'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.successful,
      ),
      description: json['description'] as String,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
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
