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
        return 'Per-Unit Quantity Rate';
      case PricingModelType.tieredChips:
        return 'Package Chips';
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
  final double workerReward;
  final List<PriceChipModel> chips;

  const PricingConfig({
    this.modelType = PricingModelType.fixed,
    required this.buyerPrice,
    this.unitPrice = 1.0,
    this.minQuantity = 1,
    this.maxQuantity = 10000,
    required this.adminMarginPercent,
    required this.workerReward,
    this.chips = const [],
  });
  factory PricingConfig.calculate({
    PricingModelType modelType = PricingModelType.fixed,
    required double buyerPrice,
    double unitPrice = 1.0,
    int minQuantity = 1,
    int maxQuantity = 10000,
    required double adminMarginPercent,
    List<PriceChipModel> chips = const [],
  }) {
    final marginFraction = adminMarginPercent / 100.0;
    final effectivePrice = modelType == PricingModelType.fixed
        ? buyerPrice
        : (chips.isNotEmpty ? chips.first.price : buyerPrice);
    final calculatedReward = effectivePrice * (1.0 - marginFraction);

    return PricingConfig(
      modelType: modelType,
      buyerPrice: buyerPrice,
      unitPrice: unitPrice,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      adminMarginPercent: adminMarginPercent,
      workerReward: calculatedReward < 0 ? 0 : calculatedReward,
      chips: chips,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelType': modelType.name,
      'buyerPrice': buyerPrice,
      'unitPrice': unitPrice,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'adminMarginPercent': adminMarginPercent,
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
      buyerPrice: (json['buyerPrice'] ?? json['unitPriceBuyer'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] ?? json['unitPriceBuyer'] as num?)?.toDouble() ?? 1.0,
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
      maxQuantity: (json['maxQuantity'] as num?)?.toInt() ?? 10000,
      adminMarginPercent: (json['adminMarginPercent'] as num?)?.toDouble() ?? 20.0,
      workerReward: (json['workerReward'] ?? json['workerRewardPerUnit'] as num?)?.toDouble() ?? 0.0,
      chips: parsedChips,
    );
  }
}
