class SearchResultItem {
  const SearchResultItem({
    this.offerId,
    this.dealType,
    this.title,
    this.imageUrl,
    this.processedAddress,
    this.numberOfRooms,
    this.livingArea,
    this.propertyTypeCode,
    this.salePrice,
    this.rentGross,
  });

  final String? offerId;
  final String? dealType;
  final String? title;
  final String? imageUrl;
  final String? processedAddress;
  final num? numberOfRooms;
  final num? livingArea;
  final String? propertyTypeCode;
  final num? salePrice;
  final num? rentGross;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    final images = json['Images'] as List?;
    final imageUrl = images != null && images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['Url'] as String?
        : null;

    final addressJson = json['Address'] as Map<String, dynamic>?;
    String? processedAddress;
    if (addressJson != null) {
      const seq = ['Street', 'HouseNumber', 'PostCode', 'City'];
      final parts = seq
          .map((k) => addressJson[k] as String?)
          .where((v) => v != null && v.isNotEmpty)
          .join(' ');
      processedAddress = parts.isNotEmpty ? parts : null;
    }

    final propertyTypeJson = json['PropertyType'] as Map<String, dynamic>?;
    final rawOfferId = json['OfferId'];

    return SearchResultItem(
      offerId: rawOfferId?.toString(),
      dealType: json['DealType'] as String?,
      title: json['Title'] as String?,
      imageUrl: imageUrl,
      processedAddress: processedAddress,
      numberOfRooms: json['NumberOfRooms'] as num?,
      livingArea: json['LivingArea'] as num?,
      propertyTypeCode: propertyTypeJson?['Code'] as String?,
      salePrice: json['SalePrice'] as num?,
      rentGross: json['RentGross'] as num?,
    );
  }

  bool get isRent => dealType?.toLowerCase() == 'rent';

  String get priceLabel {
    final price = isRent ? rentGross : salePrice;
    if (price == null || price == 0) return '—';
    return _formatCurrency(price.toDouble());
  }

  static String _formatCurrency(double value) {
    if (value >= 1e9) return '€ ${(value / 1e9).toStringAsFixed(2)}B.';
    if (value >= 1e6) return '€ ${(value / 1e6).toStringAsFixed(2)}Mio.';
    if (value >= 1e3) return '€ ${(value / 1e3).toStringAsFixed(2)}Tsd.';
    return '€ ${value.toStringAsFixed(0)}';
  }
}

class OfferSearchResult {
  const OfferSearchResult({required this.items, required this.totalItems});

  final List<SearchResultItem> items;
  final int totalItems;
}
