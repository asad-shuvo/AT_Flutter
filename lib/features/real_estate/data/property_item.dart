enum PropertyListSource { observation, valuation, search }

class PropertyListConfig {
  const PropertyListConfig({
    required this.source,
    required this.commandCardTitleKey,
    required this.dateLabelKey,
    required this.tag,
  });

  final PropertyListSource source;
  final String commandCardTitleKey;
  final String dateLabelKey;
  final String tag;

  static const observation = PropertyListConfig(
    source: PropertyListSource.observation,
    commandCardTitleKey: 'tns.recentlyObserved',
    dateLabelKey: 'tns.observedOn',
    tag: 'Is-A-Observation',
  );

  static const valuation = PropertyListConfig(
    source: PropertyListSource.valuation,
    commandCardTitleKey: 'tns.recentlyValuated',
    dateLabelKey: 'tns.valuatedOn',
    tag: 'Is-A-Valuation',
  );

  static const search = PropertyListConfig(
    source: PropertyListSource.search,
    commandCardTitleKey: 'tns.recentlySearched',
    dateLabelKey: 'tns.searchedOn',
    tag: 'Is-A-OfferSearchQuery',
  );
}

class PropertyAddress {
  const PropertyAddress({this.houseNumber, this.street, this.postCode, this.city});

  final String? houseNumber;
  final String? street;
  final String? postCode;
  final String? city;

  factory PropertyAddress.fromJson(Map<String, dynamic> json) => PropertyAddress(
        houseNumber: json['HouseNumber'] as String?,
        street: json['Street'] as String?,
        postCode: json['PostCode'] as String?,
        city: json['City'] as String?,
      );
}

class PropertyTypeInfo {
  const PropertyTypeInfo({this.code, this.subCode});

  final String? code;
  final String? subCode;

  factory PropertyTypeInfo.fromJson(Map<String, dynamic> json) => PropertyTypeInfo(
        code: json['Code'] as String?,
        subCode: json['SubCode'] as String?,
      );
}

class SalePriceRange {
  const SalePriceRange({required this.lower, required this.upper});

  final double lower;
  final double upper;

  factory SalePriceRange.fromJson(Map<String, dynamic> json) => SalePriceRange(
        lower: (json['Lower'] as num?)?.toDouble() ?? 0,
        upper: (json['Upper'] as num?)?.toDouble() ?? 0,
      );
}

class PropertyItem {
  const PropertyItem({
    required this.itemId,
    this.title,
    this.address,
    this.city,
    this.imageUrl,
    this.propertyType,
    this.tags = const [],
    this.dealType,
    this.createDate,
    this.dossierId,
    this.salePrice,
    this.salePriceRange,
    this.isMakeMeMovePriceGiven = false,
    this.isSearchAgentActive = false,
    this.purchasePrice,
    this.makeMeMovePrice,
  });

  final String itemId;
  final String? title;
  final String? address;
  final String? city;
  final String? imageUrl;
  final PropertyTypeInfo? propertyType;
  final List<String> tags;
  final String? dealType;
  final String? createDate;
  final String? dossierId;
  final double? salePrice;
  final SalePriceRange? salePriceRange;
  final bool isMakeMeMovePriceGiven;
  final bool isSearchAgentActive;
  final double? purchasePrice;
  final double? makeMeMovePrice;

  factory PropertyItem.fromJson(Map<String, dynamic> json) {
    final locationJson = json['Location'] as Map<String, dynamic>?;
    final addressJson = locationJson?['Address'] as Map<String, dynamic>?;
    final addr = addressJson != null ? PropertyAddress.fromJson(addressJson) : null;

    final streetParts = [addr?.houseNumber, addr?.street]
        .where((p) => p != null && p.isNotEmpty)
        .join(' ');
    final computedAddress = streetParts.isNotEmpty
        ? '$streetParts,${addr?.postCode != null ? ' ${addr!.postCode}' : ''}'
        : null;

    final propertyTypeJson = json['PropertyType'] as Map<String, dynamic>?;
    final propertyType =
        propertyTypeJson != null ? PropertyTypeInfo.fromJson(propertyTypeJson) : null;

    final rawTags = json['Tags'];
    final tags = rawTags is List ? rawTags.whereType<String>().toList() : <String>[];

    return PropertyItem(
      itemId: json['ItemId'] as String? ?? '',
      title: json['Title'] as String?,
      address: computedAddress?.trim(),
      city: addr?.city,
      imageUrl: json['ImageUrl'] as String?,
      propertyType: propertyType,
      tags: tags,
      dealType: json['DealType'] as String?,
      createDate: json['CreateDate'] as String?,
      dossierId: json['DossierId'] as String?,
      isMakeMeMovePriceGiven: json['IsMakeMeMovePriceGiven'] as bool? ?? false,
      isSearchAgentActive: json['IsSearchAgentActive'] as bool? ?? false,
      purchasePrice: (json['PurchasePrice'] as num?)?.toDouble(),
      makeMeMovePrice: (json['MakeMeMovePrice'] as num?)?.toDouble(),
    );
  }

  factory PropertyItem.fromSearchQueryJson(Map<String, dynamic> json) {
    final refLocationJson = json['ReferenceLocation'] as Map<String, dynamic>?;
    final addressJson = refLocationJson?['Address'] as Map<String, dynamic>?;
    final addr = addressJson != null ? PropertyAddress.fromJson(addressJson) : null;

    final streetParts = [addr?.houseNumber, addr?.street]
        .where((p) => p != null && p.isNotEmpty)
        .join(' ');
    final computedAddress = streetParts.isNotEmpty
        ? '$streetParts,${addr?.postCode != null ? ' ${addr!.postCode}' : ''}'
        : addr?.postCode;

    return PropertyItem(
      itemId: json['ItemId'] as String? ?? '',
      title: json['Title'] as String?,
      address: computedAddress?.trim(),
      city: addr?.city,
      imageUrl: json['ImageUrl'] as String?,
      dealType: json['DealType'] as String?,
      createDate: json['CreateDate'] as String?,
      isSearchAgentActive: json['IsSearchAgentActive'] as bool? ?? false,
    );
  }

  PropertyItem copyWith({
    double? salePrice,
    SalePriceRange? salePriceRange,
    String? imageUrl,
    List<String>? tags,
    bool? isMakeMeMovePriceGiven,
    double? purchasePrice,
  }) {
    return PropertyItem(
      itemId: itemId,
      title: title,
      address: address,
      city: city,
      imageUrl: imageUrl ?? this.imageUrl,
      propertyType: propertyType,
      tags: tags ?? this.tags,
      dealType: dealType,
      createDate: createDate,
      dossierId: dossierId,
      salePrice: salePrice ?? this.salePrice,
      salePriceRange: salePriceRange ?? this.salePriceRange,
      isMakeMeMovePriceGiven: isMakeMeMovePriceGiven ?? this.isMakeMeMovePriceGiven,
      isSearchAgentActive: isSearchAgentActive,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      makeMeMovePrice: makeMeMovePrice,
    );
  }

  PropertyItem withMakeMovePrice(double? price) => PropertyItem(
    itemId: itemId,
    title: title,
    address: address,
    city: city,
    imageUrl: imageUrl,
    propertyType: propertyType,
    tags: tags,
    dealType: dealType,
    createDate: createDate,
    dossierId: dossierId,
    salePrice: salePrice,
    salePriceRange: salePriceRange,
    isMakeMeMovePriceGiven: price != null,
    isSearchAgentActive: isSearchAgentActive,
    purchasePrice: purchasePrice,
    makeMeMovePrice: price,
  );
}

class PropertyListResult {
  const PropertyListResult({required this.items, required this.totalCount});

  final List<PropertyItem> items;
  final int totalCount;
}
