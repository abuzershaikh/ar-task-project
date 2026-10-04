import 'package:equatable/equatable.dart';

/// Transaction types in wallet
enum TransactionType {
  credit,     // Balance added
  debit,      // Balance deducted
  reserved,   // Amount reserved for campaign
  captured,   // Reserved amount captured
  released,   // Reserved amount released back
  refund,     // Refund credited
}

/// Transaction status
enum TransactionStatus {
  pending,
  processing,
  successful,
  failed,
  reversed,
}

/// Transaction entity for wallet operations
class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final TransactionStatus status;
  final String description;
  final String? referenceId;  // Campaign ID, Payment ID, etc.
  final String? referenceType; // 'campaign', 'payment', 'refund'
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.description,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.metadata,
  });

  /// Check if transaction is credit type
  bool get isCredit => type == TransactionType.credit || 
                       type == TransactionType.refund || 
                       type == TransactionType.released;

  /// Check if transaction is debit type
  bool get isDebit => type == TransactionType.debit || 
                      type == TransactionType.reserved ||
                      type == TransactionType.captured;

  /// Get formatted amount with sign
  String getFormattedAmount() {
    final sign = isCredit ? '+' : '−';
    return '$sign ₹${amount.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        balanceBefore,
        balanceAfter,
        status,
        description,
        referenceId,
        referenceType,
        createdAt,
        metadata,
      ];

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    TransactionStatus? status,
    String? description,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      status: status ?? this.status,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
