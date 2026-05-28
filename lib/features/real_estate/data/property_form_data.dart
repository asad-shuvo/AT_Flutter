class PropertyFormData {
  const PropertyFormData({
    this.propertyId,
    required this.title,
    required this.propertyTypeCode,
    required this.dealType,
    this.purchasePrice,
    required this.street,
    required this.postCode,
    required this.houseNumber,
    required this.city,
    this.lat,
    this.lng,
    this.livingArea,
    this.landArea,
    this.gardenArea,
    this.balconyArea,
    required this.numberOfRooms,
    this.numberOfFloorsInBuilding,
    this.floorNumber,
    required this.buildingYear,
    this.numberOfBathrooms,
    this.numberOfIndoorParkingSpaces,
    this.numberOfOutdoorParkingSpaces,
    this.isNew = false,
    this.hasPool = false,
    this.hasSauna = false,
    this.hasLift = false,
    this.kitchenQuality = 0,
    this.bathroomsQuality = 0,
    this.flooringQuality = 0,
    this.windowsQuality = 0,
    this.masonryQuality = 0,
    this.kitchenCondition = 0,
    this.bathroomsCondition = 0,
    this.flooringCondition = 0,
    this.windowsCondition = 0,
    this.masonryCondition = 0,
    this.existingTags,
  });

  final String? propertyId;
  final String title;
  final String propertyTypeCode; // 'HOUSE' or 'APARTMENT'
  final String dealType; // 'sale' or 'rent'
  final double? purchasePrice;
  final String street;
  final String postCode;
  final String houseNumber;
  final String city;
  final double? lat;
  final double? lng;
  final double? livingArea;
  final double? landArea; // house only
  final double? gardenArea; // apartment only
  final double? balconyArea;
  final int numberOfRooms;
  final int? numberOfFloorsInBuilding; // apartment only
  final int? floorNumber; // apartment only
  final int buildingYear;
  final int? numberOfBathrooms;
  final int? numberOfIndoorParkingSpaces;
  final int? numberOfOutdoorParkingSpaces;
  final bool isNew;
  final bool hasPool; // house only
  final bool hasSauna; // house only
  final bool hasLift; // apartment only
  // Quality: 0=unrated, 1=simple, 2=normal, 3=highQuality, 4=luxury
  final int kitchenQuality;
  final int bathroomsQuality;
  final int flooringQuality;
  final int windowsQuality;
  final int masonryQuality; // house only
  // Condition: 0=unrated, 1=renovationNeeded, 2=wellMaintained, 3=recentlyRenovated
  final int kitchenCondition;
  final int bathroomsCondition;
  final int flooringCondition;
  final int windowsCondition;
  final int masonryCondition; // house only
  final List<String>? existingTags;

  bool get isApartment => propertyTypeCode.toUpperCase() == 'APARTMENT';

  factory PropertyFormData.fromJson(Map<String, dynamic> json) {
    final locationJson = json['Location'] as Map<String, dynamic>?;
    final addressJson = locationJson?['Address'] as Map<String, dynamic>?;
    final qualityJson = json['Quality'] as Map<String, dynamic>?;
    final conditionJson = json['Condition'] as Map<String, dynamic>?;
    final tags = (json['Tags'] as List?)?.cast<String>();

    return PropertyFormData(
      propertyId: json['ItemId'] as String?,
      title: json['Title'] as String? ?? '',
      propertyTypeCode: (json['PropertyType'] as Map<String, dynamic>?)?['Code'] as String? ?? 'HOUSE',
      dealType: json['DealType'] as String? ?? '',
      purchasePrice: (json['PurchasePrice'] as num?)?.toDouble(),
      street: addressJson?['Street'] as String? ?? '',
      postCode: addressJson?['PostCode'] as String? ?? '',
      houseNumber: addressJson?['HouseNumber'] as String? ?? '',
      city: addressJson?['City'] as String? ?? '',
      livingArea: (json['LivingArea'] as num?)?.toDouble(),
      landArea: (json['LandArea'] as num?)?.toDouble(),
      gardenArea: (json['GardenArea'] as num?)?.toDouble(),
      balconyArea: (json['BalconyArea'] as num?)?.toDouble(),
      numberOfRooms: (json['NumberOfRooms'] as num?)?.toInt() ?? 1,
      numberOfFloorsInBuilding: (json['NumberOfFloorsInBuilding'] as num?)?.toInt(),
      floorNumber: (json['FloorNumber'] as num?)?.toInt(),
      buildingYear: (json['BuildingYear'] as num?)?.toInt() ?? 1850,
      numberOfBathrooms: (json['NumberOfBathrooms'] as num?)?.toInt(),
      numberOfIndoorParkingSpaces: (json['NumberOfIndoorParkingSpaces'] as num?)?.toInt(),
      numberOfOutdoorParkingSpaces: (json['NumberOfOutdoorParkingSpaces'] as num?)?.toInt(),
      isNew: json['IsNew'] as bool? ?? false,
      hasPool: json['HasPool'] as bool? ?? false,
      hasSauna: json['HasSauna'] as bool? ?? false,
      hasLift: json['HasLift'] as bool? ?? false,
      kitchenQuality: _parseQuality(qualityJson?['Kitchen']),
      bathroomsQuality: _parseQuality(qualityJson?['Bathrooms']),
      flooringQuality: _parseQuality(qualityJson?['Flooring']),
      windowsQuality: _parseQuality(qualityJson?['Windows']),
      masonryQuality: _parseQuality(qualityJson?['Masonry']),
      kitchenCondition: _parseCondition(conditionJson?['Kitchen']),
      bathroomsCondition: _parseCondition(conditionJson?['Bathrooms']),
      flooringCondition: _parseCondition(conditionJson?['Flooring']),
      windowsCondition: _parseCondition(conditionJson?['Windows']),
      masonryCondition: _parseCondition(conditionJson?['Masonry']),
      existingTags: tags,
    );
  }

  Map<String, dynamic> toPayload({
    required String personId,
    required String tag,
    required List<String> valuationDates,
  }) {
    final payload = <String, dynamic>{
      'Type': tag,
      'PersonId': personId,
      'PropertyTypeCode': propertyTypeCode.toLowerCase(),
      'DealType': dealType,
      'Title': title,
      'ValuationDates': valuationDates,
      'Latitude': lat,
      'Longitude': lng,
      'PostCode': postCode,
      'City': city,
      'Street': street,
      'HouseNumber': houseNumber,
      'CountryCode': 'AT',
      'NumberOfRooms': numberOfRooms,
      'NumberOfBathrooms': numberOfBathrooms ?? 1,
      'NumberOfIndoorParkingSpaces': numberOfIndoorParkingSpaces ?? 0,
      'NumberOfOutdoorParkingSpaces': numberOfOutdoorParkingSpaces ?? 0,
      'IsNew': isNew,
      'LivingArea': (livingArea ?? 10).toInt(),
      'BuildingYear': buildingYear,
      'KitchenQuality': _qualityString(kitchenQuality),
      'FlooringQuality': _qualityString(flooringQuality),
      'WindowsQuality': _qualityString(windowsQuality),
      'BathroomsQuality': _qualityString(bathroomsQuality),
      'KitchenCondition': _conditionString(kitchenCondition),
      'FlooringCondition': _conditionString(flooringCondition),
      'WindowsCondition': _conditionString(windowsCondition),
      'BathroomsCondition': _conditionString(bathroomsCondition),
    };

    if (propertyId != null) payload['PropertyId'] = propertyId;
    if (purchasePrice != null) payload['PurchasePrice'] = purchasePrice;
    if (balconyArea != null) payload['BalconyArea'] = balconyArea!.toInt();

    if (isApartment) {
      payload['HasLift'] = hasLift;
      payload['HasPool'] = false;
      payload['HasSauna'] = false;
      payload['MasonryQuality'] = null;
      payload['MasonryCondition'] = null;
      if (gardenArea != null) payload['GardenArea'] = gardenArea!.toInt();
      if (numberOfFloorsInBuilding != null) {
        payload['NumberOfFloorsInBuilding'] = numberOfFloorsInBuilding;
      }
      if (floorNumber != null) payload['FloorNumber'] = floorNumber;
    } else {
      payload['HasPool'] = hasPool;
      payload['HasSauna'] = hasSauna;
      payload['HasLift'] = false;
      payload['LandArea'] = (landArea ?? 50).toInt();
      payload['MasonryQuality'] = _qualityString(masonryQuality);
      payload['MasonryCondition'] = _conditionString(masonryCondition);
    }

    if (existingTags != null && existingTags!.isNotEmpty) {
      payload['Tags'] = existingTags;
    }

    return payload;
  }

  static int _parseQuality(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'simple': return 1;
        case 'normal': return 2;
        case 'high_quality': return 3;
        case 'luxury': return 4;
      }
    }
    return 0;
  }

  static int _parseCondition(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'renovation_needed': return 1;
        case 'well_maintained': return 2;
        case 'new_or_recently_renovated': return 3;
      }
    }
    return 0;
  }

  static String? _qualityString(int v) {
    switch (v) {
      case 1: return 'simple';
      case 2: return 'normal';
      case 3: return 'high_quality';
      case 4: return 'luxury';
      default: return null;
    }
  }

  static String? _conditionString(int v) {
    switch (v) {
      case 1: return 'renovation_needed';
      case 2: return 'well_maintained';
      case 3: return 'new_or_recently_renovated';
      default: return null;
    }
  }
}
