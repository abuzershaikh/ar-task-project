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
    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }
    int parseI(dynamic v) {
      if (v == null) return 1;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 1;
      return 1;
    }

    return PriceChipModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      quantity: parseI(json['quantity']),
      price: parseD(json['price']),
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
    double parseD(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }
    int parseI(dynamic v, int def) {
      if (v == null) return def;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    PricingModelType parsedModel = PricingModelType.fixed;
    final mStr = json['modelType']?.toString();
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
      buyerPrice: parseD(json['buyerPrice'] ?? json['unitPriceBuyer'] ?? json['price'], 0.0),
      unitPrice: parseD(json['unitPrice'] ?? json['unitPriceBuyer'], 1.0),
      minQuantity: parseI(json['minQuantity'], 1),
      maxQuantity: parseI(json['maxQuantity'], 10000),
      adminMarginPercent: parseD(json['adminMarginPercent'] ?? json['marginValue'], 20.0),
      workerReward: parseD(json['workerReward'] ?? json['workerRewardPerUnit'], 0.0),
      chips: parsedChips,
    );
  }
}
