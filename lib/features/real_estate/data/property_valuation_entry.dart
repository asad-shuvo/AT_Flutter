import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';

class PropertyValuationEntry {
  const PropertyValuationEntry({
    required this.valuationDate,
    this.salePrice,
    this.rentGross,
    this.salePriceRange,
    this.rentGrossRange,
    this.confidence,
  });

  final String valuationDate;
  final double? salePrice;
  final double? rentGross;
  final SalePriceRange? salePriceRange;
  final SalePriceRange? rentGrossRange;
  final String? confidence;

  factory PropertyValuationEntry.fromJson(Map<String, dynamic> json) {
    final spRange = json['SalePriceRange'] as Map<String, dynamic>?;
    final rgRange = json['RentGrossRange'] as Map<String, dynamic>?;
    return PropertyValuationEntry(
      valuationDate: json['ValuationDate'] as String? ?? '',
      salePrice: (json['SalePrice'] as num?)?.toDouble(),
      rentGross: (json['RentGross'] as num?)?.toDouble(),
      salePriceRange: spRange != null ? SalePriceRange.fromJson(spRange) : null,
      rentGrossRange: rgRange != null ? SalePriceRange.fromJson(rgRange) : null,
      confidence: json['Confidence'] as String?,
    );
  }
}
