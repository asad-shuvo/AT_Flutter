class SearchQueryFormData {
  const SearchQueryFormData({
    required this.itemId,
    this.title = '',
    this.postCode = '',
    this.city = '',
    this.radiusKm = 1,
    this.dealType = '',
    this.propertyTypeCode,
    this.minLivingArea = 10,
    this.maxLivingArea = 800,
    this.minRooms = 1,
    this.maxRooms = 20,
    this.minBuildingYear = 1850,
    this.maxBuildingYear = 2028,
    this.isWheelchairAccessible,
    this.hasLift,
    this.hasParkingSpaces,
    this.maxDistanceHospital,
    this.maxDistanceGroceryStore,
    this.maxDistancePublicTransport,
    this.minSalePrice,
    this.maxSalePrice,
    this.minRentGross,
    this.maxRentGross,
    this.minLandArea = 50,
    this.maxLandArea = 5000,
    this.lat,
    this.lng,
  });

  final String itemId;
  final String title;
  final String postCode;
  final String city;
  final double radiusKm;
  final String dealType;
  final String? propertyTypeCode;
  final double minLivingArea;
  final double maxLivingArea;
  final int minRooms;
  final int maxRooms;
  final int minBuildingYear;
  final int maxBuildingYear;
  final bool? isWheelchairAccessible;
  final bool? hasLift;
  final bool? hasParkingSpaces;
  final int? maxDistanceHospital;
  final int? maxDistanceGroceryStore;
  final int? maxDistancePublicTransport;
  final int? minSalePrice;
  final int? maxSalePrice;
  final int? minRentGross;
  final int? maxRentGross;
  final double minLandArea;
  final double maxLandArea;
  final double? lat;
  final double? lng;

  factory SearchQueryFormData.fromJson(Map<String, dynamic> json) {
    final refLoc = json['ReferenceLocation'] as Map<String, dynamic>?;
    final addr = refLoc?['Address'] as Map<String, dynamic>?;
    final postCode = addr?['PostCode'] as String? ?? '';
    final city = addr?['City'] as String? ?? '';

    final coords = refLoc?['Coordinates'] as Map<String, dynamic>?;
    final lat = (coords?['Latitude'] as num?)?.toDouble();
    final lng = (coords?['Longitude'] as num?)?.toDouble();

    final location = json['Location'] as List?;
    final locObj = location?.isNotEmpty == true ? location!.first as Map<String, dynamic>? : null;
    final circle = locObj?['Circle'] as Map<String, dynamic>?;
    final radiusM = (circle?['Radius'] as num?)?.toDouble();
    final radiusKm = radiusM != null ? radiusM / 1000 : 1.0;

    final propTypes = json['PropertyType'] as List?;
    final propTypeObj = propTypes?.isNotEmpty == true ? propTypes!.first as Map<String, dynamic>? : null;
    final propertyTypeCode = propTypeObj?['Code'] as String?;

    return SearchQueryFormData(
      itemId: json['ItemId'] as String? ?? '',
      title: json['Title'] as String? ?? '',
      postCode: postCode,
      city: city,
      radiusKm: radiusKm,
      dealType: json['DealType'] as String? ?? '',
      propertyTypeCode: propertyTypeCode,
      minLivingArea: (json['MinimumLivingArea'] as num?)?.toDouble() ?? 10,
      maxLivingArea: (json['MaximumLivingArea'] as num?)?.toDouble() ?? 800,
      minRooms: (json['MinimumNumberOfRooms'] as num?)?.toInt() ?? 1,
      maxRooms: (json['MaximumNumberOfRooms'] as num?)?.toInt() ?? 20,
      minBuildingYear: (json['MinimumBuildingYear'] as num?)?.toInt() ?? 1850,
      maxBuildingYear: (json['MaximumBuildingYear'] as num?)?.toInt() ?? 2028,
      isWheelchairAccessible: json['IsWheelchairAccessible'] as bool?,
      hasLift: json['HasLift'] as bool?,
      hasParkingSpaces: json['HasParkingSpaces'] as bool?,
      maxDistanceHospital: (json['MaximumDistanceHospital'] as num?)?.toInt(),
      maxDistanceGroceryStore: (json['MaximumDistanceGroceryStore'] as num?)?.toInt(),
      maxDistancePublicTransport: (json['MaximumDistancePublicTransport'] as num?)?.toInt(),
      minSalePrice: _nonZero(json['MinimumSalePrice']),
      maxSalePrice: _nonZero(json['MaximumSalePrice']),
      minRentGross: _nonZero(json['MinimumRentGross']),
      maxRentGross: _nonZero(json['MaximumRentGross']),
      minLandArea: (json['MinimumLandArea'] as num?)?.toDouble() ?? 50,
      maxLandArea: (json['MaximumLandArea'] as num?)?.toDouble() ?? 5000,
      lat: lat,
      lng: lng,
    );
  }

  static int? _nonZero(dynamic v) {
    final n = (v as num?)?.toInt();
    return (n != null && n > 0) ? n : null;
  }
}
