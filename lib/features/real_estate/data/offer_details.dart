import 'package:flutter/foundation.dart';

@immutable
class OfferDetails {
  const OfferDetails({
    this.offerId,
    this.dealType,
    this.title,
    this.description,
    this.imageUrls = const [],
    this.url,
    this.salePrice,
    this.rentGross,
    this.processedAddress,
    this.latitude,
    this.longitude,
    this.buildingYear,
    this.propertyTypeCode,
    this.livingArea,
    this.landArea,
    this.numberOfRooms,
  });

  final String? offerId;
  final String? dealType;
  final String? title;
  final String? description;
  final List<String> imageUrls;
  final String? url;
  final double? salePrice;
  final double? rentGross;
  final String? processedAddress;
  final double? latitude;
  final double? longitude;
  final int? buildingYear;
  final String? propertyTypeCode;
  final num? livingArea;
  final num? landArea;
  final num? numberOfRooms;

  bool get isForRent => dealType?.toLowerCase() == 'rent';
  double? get offerPrice => isForRent ? rentGross : salePrice;

  String get priceLabel {
    final price = offerPrice;
    if (price == null) return '—';
    String formatted;
    if (price >= 1000000000) {
      formatted = '${(price / 1000000000).toStringAsFixed(2)} B.';
    } else if (price >= 1000000) {
      formatted = '${(price / 1000000).toStringAsFixed(2)} Mio.';
    } else if (price >= 1000) {
      formatted = '${(price / 1000).toStringAsFixed(0)} Tsd.';
    } else {
      formatted = price.toStringAsFixed(0);
    }
    return isForRent ? '$formatted / Monat' : formatted;
  }

  String get mapUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  factory OfferDetails.fromJson(Map<String, dynamic> json) {
    final addr = json['Address'] as Map<String, dynamic>?;
    final parts = <String>[];
    for (final key in ['Street', 'HouseNumber', 'PostCode', 'City']) {
      final val = addr?[key] as String?;
      if (val != null && val.isNotEmpty) parts.add(val);
    }

    final coords = json['Coordinates'] as Map<String, dynamic>?;
    final imageUrls = (json['Images'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map((img) => img['Url'] as String?)
            .whereType<String>()
            .take(5)
            .toList() ??
        [];
    final pt = json['PropertyType'] as Map<String, dynamic>?;

    return OfferDetails(
      offerId: json['OfferId'] as String?,
      dealType: json['DealType'] as String?,
      title: json['Title'] as String?,
      description: json['Description'] as String?,
      imageUrls: imageUrls,
      url: json['Url'] as String?,
      salePrice: (json['SalePrice'] as num?)?.toDouble(),
      rentGross: (json['RentGross'] as num?)?.toDouble(),
      processedAddress: parts.isEmpty ? null : parts.join(' '),
      latitude: (coords?['Latitude'] as num?)?.toDouble(),
      longitude: (coords?['Longitude'] as num?)?.toDouble(),
      buildingYear: json['BuildingYear'] as int?,
      propertyTypeCode: pt?['Code'] as String?,
      livingArea: json['LivingArea'] as num?,
      landArea: json['LandArea'] as num?,
      numberOfRooms: json['NumberOfRooms'] as num?,
    );
  }
}
