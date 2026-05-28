import 'package:flutter/foundation.dart';

@immutable
class OfferValuationData {
  const OfferValuationData({
    this.priceLower,
    this.priceUpper,
    this.confidence,
    this.isForRent = false,
  });

  final double? priceLower;
  final double? priceUpper;
  final String? confidence;
  final bool isForRent;

  String _fmt(double price) {
    final str = price.toStringAsFixed(2);
    final dotIdx = str.indexOf('.');
    final intPart = str.substring(0, dotIdx);
    final decPart = str.substring(dotIdx + 1);
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }
    return '€ ${buf.toString()},$decPart';
  }

  String get priceRangeLabel {
    final lo = priceLower;
    final hi = priceUpper;
    if (lo == null && hi == null) return '—';
    if (lo != null && hi != null) return '${_fmt(lo)} - ${_fmt(hi)}';
    return _fmt((lo ?? hi)!);
  }
}

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
    final str = price.toStringAsFixed(2);
    final dotIdx = str.indexOf('.');
    final intPart = str.substring(0, dotIdx);
    final decPart = str.substring(dotIdx + 1);
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }
    final formatted = '€ ${buf.toString()},$decPart';
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
