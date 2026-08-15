enum PricingModelType {
  fixed,
  countBased,
  tieredChips,
}

extension PricingModelTypeExtension on PricingModelType {
  String get label {
    switch (this) {
      case PricingModelType.fixed:
        return 'Fixed Price (Flat Rate)';
      case PricingModelType.countBased:
        return 'Per-Unit Quantity Rate (Count Based)';
      case PricingModelType.tieredChips:
        return 'Pre-Configured Chip Package Cards';
    }
  }
}

class PriceChipModel {
  final String id;
  final String label;
  final int quantity;
  final double price;
  final bool isPopular;

  const PriceChipModel({
    required this.id,
    required this.label,
    required this.quantity,
    required this.price,
    this.isPopular = false,
  });

  PriceChipModel copyWith({
    String? id,
    String? label,
    int? quantity,
    double? price,
    bool? isPopular,
  }) {
    return PriceChipModel(
      id: id ?? this.id,
      label: label ?? this.label,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'quantity': quantity,
      'price': price,
      'isPopular': isPopular,
    };
  }

  factory PriceChipModel.fromJson(Map<String, dynamic> json) {
    return PriceChipModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }
}

class PricingConfig {
  final PricingModelType modelType;
  final double buyerPrice;
  final double unitPrice;
  final int minQuantity;
  final int maxQuantity;
  final double adminMarginPercent;
  final String marginType;
  final double workerReward;
  final List<PriceChipModel> chips;

  const PricingConfig({
    this.modelType = PricingModelType.fixed,
    required this.buyerPrice,
    this.unitPrice = 1.0,
    this.minQuantity = 1,
    this.maxQuantity = 10000,
    required this.adminMarginPercent,
    this.marginType = 'PERCENTAGE',
    required this.workerReward,
    this.chips = const [],
  });

  /// Factory constructor that calculates real-time Worker Reward
  factory PricingConfig.calculate({
    PricingModelType modelType = PricingModelType.fixed,
    required double buyerPrice,
    double unitPrice = 1.0,
    int minQuantity = 1,
    int maxQuantity = 10000,
    required double adminMarginPercent,
    String marginType = 'PERCENTAGE',
    List<PriceChipModel> chips = const [],
  }) {
    final effectivePrice = modelType == PricingModelType.fixed
        ? buyerPrice
        : (chips.isNotEmpty ? chips.first.price : buyerPrice);
        
    final double calculatedReward;
    if (marginType.toUpperCase() == 'FIXED') {
      calculatedReward = effectivePrice - adminMarginPercent;
    } else {
      final marginFraction = adminMarginPercent / 100.0;
      calculatedReward = effectivePrice * (1.0 - marginFraction);
    }

    return PricingConfig(
      modelType: modelType,
      buyerPrice: buyerPrice,
      unitPrice: unitPrice,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      adminMarginPercent: adminMarginPercent,
      marginType: marginType,
      workerReward: calculatedReward < 0 ? 0 : calculatedReward,
      chips: chips,
    );
  }

  PricingConfig copyWith({
    PricingModelType? modelType,
    double? buyerPrice,
    double? unitPrice,
    int? minQuantity,
    int? maxQuantity,
    double? adminMarginPercent,
    String? marginType,
    double? workerReward,
    List<PriceChipModel>? chips,
  }) {
    return PricingConfig(
      modelType: modelType ?? this.modelType,
      buyerPrice: buyerPrice ?? this.buyerPrice,
      unitPrice: unitPrice ?? this.unitPrice,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      adminMarginPercent: adminMarginPercent ?? this.adminMarginPercent,
      marginType: marginType ?? this.marginType,
      workerReward: workerReward ?? this.workerReward,
      chips: chips ?? this.chips,
    );
  }

  /// Validation engine rule: Margin % must be valid, worker reward > 0
  bool get isValid {
    return buyerPrice >= 0 &&
        adminMarginPercent >= 0 &&
        adminMarginPercent <= 100 &&
        workerReward >= 0;
  }

  String? get validationError {
    if (adminMarginPercent < 0 || adminMarginPercent > 100) {
      return 'Margin percentage must be between 0% and 100%';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'modelType': modelType.name,
      'buyerPrice': buyerPrice,
      'unitPrice': unitPrice,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'adminMarginPercent': adminMarginPercent,
      'marginType': marginType,
      'workerReward': workerReward,
      'chips': chips.map((c) => c.toJson()).toList(),
    };
  }

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    PricingModelType parsedModel = PricingModelType.fixed;
    final mStr = json['modelType'] as String?;
    if (mStr != null) {
      parsedModel = PricingModelType.values.firstWhere(
        (e) => e.name == mStr,
        orElse: () => PricingModelType.fixed,
      );
    }

    final rawChips = json['chips'] as List<dynamic>?;
    final parsedChips = rawChips != null
        ? rawChips.map((c) => PriceChipModel.fromJson(c as Map<String, dynamic>)).toList()
        : <PriceChipModel>[];

    return PricingConfig(
      modelType: parsedModel,
      buyerPrice: (json['buyerPrice'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 1.0,
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
      maxQuantity: (json['maxQuantity'] as num?)?.toInt() ?? 10000,
      adminMarginPercent: (json['adminMarginPercent'] as num?)?.toDouble() ?? 20.0,
      marginType: json['marginType']?.toString() ?? 'PERCENTAGE',
      workerReward: (json['workerReward'] as num?)?.toDouble() ?? 0.0,
      chips: parsedChips,
    );
  }
}
