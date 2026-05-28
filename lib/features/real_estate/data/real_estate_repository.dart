import 'dart:convert';
import 'dart:math';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/core/network/sql_query_builder.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/real_estate/data/offer_details.dart';
import 'package:filip_at_flutter/features/real_estate/data/place_address_result.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_form_data.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_valuation_entry.dart';
import 'package:filip_at_flutter/features/real_estate/data/search_query_form_data.dart';
import 'package:filip_at_flutter/features/real_estate/data/search_result_item.dart';

const _offerSearchQueryFields = [
  'ItemId', 'Tags', 'CreateDate', 'Title', 'ReferenceLocation', 'CountryCode',
  'PropertyType', 'DealType', 'Location', 'HasLift', 'IsWheelchairAccessible',
  'HasParkingSpaces', 'MinimumSalePrice', 'MaximumSalePrice', 'MinimumRentGross',
  'MaximumRentGross', 'MinimumLivingArea', 'MaximumLivingArea', 'MinimumLandArea',
  'MaximumLandArea', 'MinimumNumberOfRooms', 'MaximumNumberOfRooms',
  'MinimumBuildingYear', 'MaximumBuildingYear', 'MaximumDistanceHospital',
  'MaximumDistanceGroceryStore', 'MaximumDistancePublicTransport', 'IsSearchAgentActive',
];

const _propertyFields = [
  'ItemId', 'Tags', 'Location', 'PropertyType', 'BuildingYear', 'LivingArea',
  'LandArea', 'GardenArea', 'Volume', 'NumberOfRooms', 'NumberOfBedrooms',
  'NumberOfBathrooms', 'BalconyArea', 'NumberOfIndoorParkingSpaces',
  'NumberOfOutdoorParkingSpaces', 'FloorNumber', 'HasLift', 'EnergyLabel',
  'HasSauna', 'HasPool', 'NumberOfFloorsInBuilding', 'IsFurnished', 'IsNew',
  'RenovationYear', 'Condition', 'Quality', 'NumberOfUnits', 'AnnualRentIncome',
  'CountryCode', 'PurchasePrice', 'Title', 'MakeMeMovePrice', 'DealType',
  'IsMakeMeMovePriceGiven', 'PersonId', 'CreateDate', 'DossierId',
];

const _offerFields = [
  'OfferId', 'DealType', 'StartDate', 'IsActive', 'IsNew', 'Title', 'Description',
  'Images', 'ContactInfo', 'IsExclusive', 'Url', 'SalePrice', 'RentGross', 'Currency',
  'Address', 'Coordinates', 'Distance', 'FloorNumber', 'BuildingYear', 'PropertyType',
  'LivingArea', 'LandArea', 'NumberOfRooms', 'HasLift', 'HasParkingSpaces',
  'NumberOfIndoorParkingSpaces', 'NumberOfOutdoorParkingSpaces', 'ShareableLink',
];

const _pageSize = 30;
const _marketShortCode = 'AT';

class RealEstateRepository {
  const RealEstateRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
    required String priceHubbleUrl,
  })  : _apiClient = apiClient,
        _sessionCache = userSessionCache,
        _priceHubbleUrl = priceHubbleUrl;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;
  final String _priceHubbleUrl;

  Future<String?> getPersonId() async {
    final session = await _sessionCache.resolve();
    return session?.personId;
  }

  Future<PropertyListResult> fetchProperties({
    required String tag,
    required String personId,
    required int pageNumber,
    bool excludeCount = false,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return const PropertyListResult(items: [], totalCount: 0);

    final query = SqlQueryBuilder.prepareQuery(
      entity: 'Property',
      fields: _propertyFields,
      filters: [
        {'property': 'PersonId', 'operator': '=', 'value': personId},
        {'property': 'Tags', 'operator': '=', 'value': tag},
      ],
      orderBy: 'CreateDate __desc',
      pageNumber: pageNumber,
      pageSize: _pageSize,
    );

    final result = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {
        'EntityName': 'Property',
        'Text': query,
        'ExcludeCount': excludeCount,
      },
      headers: _headers(session.accessToken),
    );

    final body = result['body'] as Map<String, dynamic>? ?? {};
    final results = body['Results'] as List? ?? [];
    final total = body['TotalRecordCount'] as int? ?? 0;

    var items = results
        .cast<Map<String, dynamic>>()
        .map(PropertyItem.fromJson)
        .toList();

    items = await _enrichWithPrices(items, session.accessToken);

    return PropertyListResult(items: items, totalCount: total);
  }

  Future<PropertyListResult> fetchSearchQueries({
    required String personId,
    required int pageNumber,
    bool excludeCount = false,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return const PropertyListResult(items: [], totalCount: 0);

    final query = SqlQueryBuilder.prepareQuery(
      entity: 'OfferSearchQuery',
      fields: _offerSearchQueryFields,
      filters: [
        {'property': 'PersonId', 'operator': '=', 'value': personId},
        {'property': 'Tags', 'operator': '=', 'value': 'Is-A-OfferSearchQuery'},
      ],
      orderBy: 'CreateDate __desc',
      pageNumber: pageNumber,
      pageSize: _pageSize,
    );

    final result = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {
        'EntityName': 'OfferSearchQuery',
        'Text': query,
        'ExcludeCount': excludeCount,
      },
      headers: _headers(session.accessToken),
    );

    final body = result['body'] as Map<String, dynamic>? ?? {};
    final results = body['Results'] as List? ?? [];
    final total = body['TotalRecordCount'] as int? ?? 0;

    final items = results
        .cast<Map<String, dynamic>>()
        .map(PropertyItem.fromSearchQueryJson)
        .toList();

    return PropertyListResult(items: items, totalCount: total);
  }

  Future<OfferSearchResult> fetchSearchResults({
    required String queryId,
    required int offset,
    required int limit,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return const OfferSearchResult(items: [], totalItems: 0);

    final payload = <String, dynamic>{
      'OfferSearchQueryId': queryId,
      'Offset': offset,
      'Limit': limit,
      'MessageCorrelationId': _uuid(),
    };

    final result = await _apiClient.postJson(
      url: '${_priceHubbleUrl}Query/SearchOffers',
      body: payload,
      headers: _headers(session.accessToken),
    );

    final body = result['body'] as Map<String, dynamic>? ?? {};
    final items = (body['Items'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(SearchResultItem.fromJson)
        .toList();
    final total = body['TotalItems'] as int? ?? 0;

    return OfferSearchResult(items: items, totalItems: total);
  }

  Future<OfferDetails?> fetchOfferDetails(String offerId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final query = SqlQueryBuilder.prepareQuery(
      entity: 'Offer',
      fields: _offerFields,
      filters: [
        {'property': 'OfferId', 'operator': '=', 'value': offerId},
      ],
      pageNumber: 0,
      pageSize: 1,
    );

    final result = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {'EntityName': 'Offer', 'Text': query, 'ExcludeCount': true},
      headers: _headers(session.accessToken),
    );

    final results = (result['body'] as Map<String, dynamic>?)?['Results'] as List? ?? [];
    if (results.isEmpty) return null;
    return OfferDetails.fromJson(results.first as Map<String, dynamic>);
  }

  Future<String?> fetchDossierShareLink(String dossierId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final result = await _apiClient.postJson(
      url: '${_priceHubbleUrl}Query/DossierSharing',
      body: {
        'DossierId': dossierId,
        'CountryCode': _marketShortCode,
        'DaysToLive': 14,
        'Locale': 'en_GB',
        'MessageCorrelationId': _uuid(),
      },
      headers: _headers(session.accessToken),
    );
    return (result['body'] as Map<String, dynamic>?)?['Url'] as String?;
  }

  Future<({bool success, bool alreadyInProgress})> requestDossierPdf({
    required String dossierId,
    required String personId,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return (success: false, alreadyInProgress: false);

    final result = await _apiClient.postJson(
      url: '${_priceHubbleUrl}Command/GenerateDossierPdf',
      body: {
        'DossierId': dossierId,
        'PersonId': personId,
        'Language': 'de_CH',
        'MessageCorrelationId': _uuid(),
      },
      headers: _headers(session.accessToken),
    );
    final body = result['body'] as Map<String, dynamic>? ?? {};
    final errors = body['Errors'] as Map<String, dynamic>?;
    final msgs = (body['ErrorMessages'] as List?)?.cast<String>() ?? [];
    return (
      success: errors?['IsValid'] == true,
      alreadyInProgress: msgs.contains('ANOTHER_PDF_GENERATION_IN_PROGRESS'),
    );
  }

  Future<void> deleteProperty({
    required String propertyId,
    required String deletedFrom,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return;

    await _apiClient.postJson(
      url: '${_priceHubbleUrl}Command/DeletePropertyRelatedInformation',
      body: {
        'PropertyId': propertyId,
        'DeletedFrom': deletedFrom,
        'MessageCorrelationId': _uuid(),
      },
      headers: _headers(session.accessToken),
    );

    await _deleteActivityLog(propertyId, session.accessToken);
  }

  Future<void> _deleteActivityLog(String entityId, String accessToken) async {
    final query =
        'Select <ItemId>from<SnActivityLog>where<ActivityEntityId=__eql($entityId)>pageNumber=<0>pageSize=<1>';
    try {
      final lookup = await _apiClient.postJson(
        url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
        body: {
          'EntityName': 'SnActivityLog',
          'Text': query,
          'ExcludeCount': true,
        },
        headers: _headers(accessToken),
      );
      final body = lookup['body'] as Map<String, dynamic>? ?? {};
      final results = body['Results'];
      if (results is! List || results.isEmpty) return;
      final first = results.first;
      if (first is! Map) return;
      final itemId = first['ItemId'] as String?;
      if (itemId == null || itemId.isEmpty) return;

      await _apiClient.postJson(
        url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Delete',
        body: {
          'EntityName': 'SnActivityLog',
          'JsonString': jsonEncode({'ItemId': itemId}),
        },
        headers: _headers(accessToken),
      );
    } catch (_) {
      // Best effort — property delete success is not blocked by log cleanup.
    }
  }

  Future<void> updatePropertyTags({
    required String itemId,
    required List<String> tags,
    required String personId,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return;

    await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Update',
      body: {
        'EntityName': 'Property',
        'JsonString': jsonEncode({'ItemId': itemId, 'Tags': tags, 'PersonId': personId}),
      },
      headers: _headers(session.accessToken),
    );
  }

  Future<PropertyItem?> fetchPropertyById(String itemId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final query = SqlQueryBuilder.prepareQuery(
      entity: 'Property',
      fields: _propertyFields,
      filters: [
        {'property': 'ItemId', 'operator': '=', 'value': itemId},
      ],
      pageNumber: 0,
      pageSize: 1,
    );
    final result = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {'EntityName': 'Property', 'Text': query, 'ExcludeCount': true},
      headers: _headers(session.accessToken),
    );
    final results = (result['body'] as Map<String, dynamic>?)?['Results'] as List? ?? [];
    if (results.isEmpty) return null;
    return PropertyItem.fromJson(results.first as Map<String, dynamic>);
  }

  static List<String> _generateValuationDates() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    final dates = <String>[];
    for (int i = 0; i < 6; i++) {
      if (i == 0) {
        dates.add('${now.year}-${pad(now.month)}-${pad(now.day)}');
      } else {
        final dt = DateTime(now.year, now.month - i, 1);
        dates.add('${dt.year}-${pad(dt.month)}-01');
      }
    }
    return dates;
  }

  Future<List<PropertyValuationEntry>> fetchPropertyValuationHistory({
    required String propertyId,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return [];

    final dates = _generateValuationDates();
    try {
      final result = await _apiClient.postJson(
        url: '${_priceHubbleUrl}Query/PropertyValuation',
        body: {
          'PropertyId': propertyId,
          'ValuationDates': dates,
          'IsDbInsertionNotRequired': true,
          'MessageCorrelationId': _uuid(),
        },
        headers: _headers(session.accessToken),
      );
      final body = result['body'] as Map<String, dynamic>? ?? {};
      final valuations = body['Valuations'] as List? ?? [];
      final map = <String, PropertyValuationEntry>{};
      for (final v in valuations) {
        if (v is! Map<String, dynamic>) continue;
        final entry = PropertyValuationEntry.fromJson(v);
        if (entry.valuationDate.length >= 7) {
          map[entry.valuationDate.substring(0, 7)] = entry;
        }
      }
      return dates
          .map((d) => map[d.substring(0, 7)] ?? PropertyValuationEntry(valuationDate: d))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProperty({
    required PropertyFormData data,
    required String personId,
    required String tag,
    required String language,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return;

    final payload = {
      ...data.toPayload(
        personId: personId,
        tag: tag,
        valuationDates: _generateValuationDates(),
      ),
      'MessageCorrelationId': _uuid(),
    };

    final result = await _apiClient.postJson(
      url: '${_priceHubbleUrl}Query/PropertyValuation',
      body: payload,
      headers: _headers(session.accessToken),
    );

    final body = result['body'] as Map<String, dynamic>? ?? {};
    final error = body['Error'] as String?;
    if (error != null && error.isNotEmpty) throw Exception(error);

    if (data.propertyId == null) {
      final propertyId = body['PropertyId'] as String?;
      if (propertyId != null) {
        final streetPart = [data.houseNumber, data.street]
            .where((s) => s.isNotEmpty).join(' ');
        final cityPart = [data.postCode, data.city]
            .where((s) => s.isNotEmpty).join(' ');
        final address = [streetPart, cityPart]
            .where((s) => s.isNotEmpty).join(', ');
        await _insertActivityLog(
          propertyId: propertyId,
          personId: personId,
          tag: tag,
          address: address,
          language: language,
          session: session,
        );
      }
    }
  }

  Future<void> _insertActivityLog({
    required String propertyId,
    required String personId,
    required String tag,
    required String address,
    required String language,
    required UserSessionData session,
  }) async {
    await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Insert',
      body: {
        'EntityName': 'SnActivityLog',
        'JsonString': jsonEncode({
          'ItemId': _uuid(),
          'Tags': ['Is-A-RealEstateOverview', tag],
          'Language': language,
          'ActionType': 'Insert',
          'ActivityEntityName': 'Property',
          'ActivityEntityId': propertyId,
          'ActivityTitle': address,
          'OrganizerPersonId': personId,
          'ActivitySource': 'MANUAL',
        }),
      },
      headers: _headers(session.accessToken),
    );
  }

  Future<PropertyFormData?> fetchPropertyFormData(String itemId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final query = SqlQueryBuilder.prepareQuery(
      entity: 'Property',
      fields: _propertyFields,
      filters: [
        {'property': 'ItemId', 'operator': '=', 'value': itemId},
      ],
      pageNumber: 0,
      pageSize: 1,
    );
    final result = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {'EntityName': 'Property', 'Text': query, 'ExcludeCount': true},
      headers: _headers(session.accessToken),
    );
    final results = (result['body'] as Map<String, dynamic>?)?['Results'] as List? ?? [];
    if (results.isEmpty) return null;
    return PropertyFormData.fromJson(results.first as Map<String, dynamic>);
  }

  Future<void> updateMakeMovePrice({
    required String itemId,
    double? price,
    required bool isGiven,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return;

    await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Update',
      body: {
        'EntityName': 'Property',
        'JsonString': jsonEncode({
          'ItemId': itemId,
          'MakeMeMovePrice': price,
          'IsMakeMeMovePriceGiven': isGiven,
        }),
      },
      headers: _headers(session.accessToken),
    );
  }

  Future<List<PropertyItem>> _enrichWithPrices(
    List<PropertyItem> items,
    String accessToken,
  ) async {
    final sale = items.where((i) => i.dealType == 'sale').toList();
    final rent = items.where((i) => i.dealType == 'rent').toList();

    if (sale.isEmpty && rent.isEmpty) return items;

    final prices = <String, double?>{};
    final ranges = <String, SalePriceRange?>{};

    Future<void> fetch(List<PropertyItem> group, String dealType) async {
      if (group.isEmpty) return;
      try {
        final inputs = group
            .map((i) => {'PropertyId': i.itemId, 'DealType': dealType})
            .toList();
        final res = await _apiClient.postJson(
          url: '${_priceHubbleUrl}Query/PropertyValuation',
          body: {
            'DealType': dealType,
            'CountryCode': _marketShortCode,
            'ValuationInputs': inputs,
            'MessageCorrelationId': _uuid(),
          },
          headers: _headers(accessToken),
        );
        final list = (res['body'] as Map<String, dynamic>?)?['ValuationList'] as List?;
        if (list == null) return;
        for (final entry in list) {
          if (entry is! List || entry.isEmpty) continue;
          final data = entry.first as Map<String, dynamic>;
          final id = data['PropertyId'] as String?;
          if (id == null) continue;
          if (dealType == 'rent') {
            prices[id] = (data['RentGross'] as num?)?.toDouble();
          } else {
            prices[id] = (data['SalePrice'] as num?)?.toDouble();
            final rangeJson = data['SalePriceRange'] as Map<String, dynamic>?;
            if (rangeJson != null) ranges[id] = SalePriceRange.fromJson(rangeJson);
          }
        }
      } catch (_) {
        // Prices are non-critical — list still shows without them.
      }
    }

    await Future.wait([fetch(sale, 'sale'), fetch(rent, 'rent')]);

    return items
        .map((i) => i.copyWith(
              salePrice: prices[i.itemId],
              salePriceRange: ranges[i.itemId],
            ))
        .toList();
  }

  Future<List<Map<String, String>>> fetchPlaces(String query) async {
    final session = await _sessionCache.resolve();
    if (session == null) return [];
    try {
      final result = await _apiClient.postJson(
        url: '${_apiClient.slsnBusinessUrl}GoogleQuery/GetPlaces',
        body: {
          'SearchQuery': Uri.encodeComponent(query),
          'CountryCode': 'at',
          'Language': 'de',
          'IsTypes': false,
        },
        headers: _headers(session.accessToken),
      );
      final predictions =
          (result['body'] as Map<String, dynamic>?)?['Predictions'] as List? ??
              [];
      return predictions
          .whereType<Map<String, dynamic>>()
          .map((p) => {
                'description': (p['description'] as String?) ?? '',
                'placeId': (p['place_id'] as String?) ?? '',
              })
          .where((p) => p['placeId']!.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PlaceAddressResult?> fetchPlaceDetails(String placeId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;
    try {
      final result = await _apiClient.postJson(
        url: '${_apiClient.slsnBusinessUrl}GoogleQuery/GetPlaceDetails',
        body: {'PlaceId': placeId, 'Language': 'de'},
        headers: _headers(session.accessToken),
      );
      final resultObj =
          (result['body'] as Map<String, dynamic>?)?['Result']
              as Map<String, dynamic>?;
      if (resultObj == null) return null;
      return _parsePlaceDetails(resultObj);
    } catch (_) {
      return null;
    }
  }

  static PlaceAddressResult _parsePlaceDetails(Map<String, dynamic> obj) {
    final components =
        (obj['address_components'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    String street = '';
    String houseNumber = '';
    String city = '';
    String postCode = '';
    String country = 'Austria';
    String countryCode = 'AT';

    for (final c in components) {
      final types = (c['types'] as List?)?.cast<String>() ?? [];
      final long = c['long_name'] as String? ?? '';
      final short = c['short_name'] as String? ?? '';
      if (types.contains('route')) {
        street = long;
      } else if (types.contains('street_number')) {
        houseNumber = long;
      } else if (types.contains('locality')) {
        city = long;
      } else if (types.contains('postal_code')) {
        postCode = long;
      } else if (types.contains('country')) {
        country = long;
        countryCode = short;
      }
    }

    final geometry = obj['geometry'] as Map<String, dynamic>?;
    final geoLoc = geometry?['location'] as Map<String, dynamic>?;
    final lat = (geoLoc?['lat'] as num?)?.toDouble();
    final lng = (geoLoc?['lng'] as num?)?.toDouble();

    final display =
        obj['formatted_address'] as String? ?? '$street $houseNumber, $postCode $city';
    return PlaceAddressResult(
      displayAddress: display,
      street: street,
      houseNumber: houseNumber,
      city: city,
      postCode: postCode,
      country: country,
      countryCode: countryCode,
      lat: lat,
      lng: lng,
    );
  }

  Future<SearchQueryFormData?> fetchSearchQueryById(String itemId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final query = SqlQueryBuilder.prepareQuery(
      entity: 'OfferSearchQuery',
      fields: _offerSearchQueryFields,
      filters: [
        {'property': 'ItemId', 'operator': '=', 'value': itemId},
      ],
      pageNumber: 0,
      pageSize: 1,
    );

    final result = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {'EntityName': 'OfferSearchQuery', 'Text': query, 'ExcludeCount': true},
      headers: _headers(session.accessToken),
    );

    final results = (result['body'] as Map<String, dynamic>?)?['Results'] as List? ?? [];
    if (results.isEmpty) return null;
    return SearchQueryFormData.fromJson(results.first as Map<String, dynamic>);
  }

  Future<void> deleteSearchQuery(String itemId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return;

    await _apiClient.postJson(
      url: '${_priceHubbleUrl}Command/DeleteOfferSearch',
      body: {'OfferSearchId': itemId, 'MessageCorrelationId': _uuid()},
      headers: _headers(session.accessToken),
    );
  }

  Future<void> updateSearchQuery({
    required String itemId,
    required String personId,
    required String title,
    required String postCode,
    required String city,
    required double radiusKm,
    required String dealType,
    required String propertyTypeCode,
    required double minLivingArea,
    required double maxLivingArea,
    required int minRooms,
    required int maxRooms,
    required int minBuildingYear,
    required int maxBuildingYear,
    bool isWheelchairAccessible = false,
    int? maxDistanceHospital,
    int? maxDistanceGroceryStore,
    int? maxDistancePublicTransport,
    bool? hasLift,
    bool? hasParkingSpaces,
    int? minSalePrice,
    int? maxSalePrice,
    int? minRentGross,
    int? maxRentGross,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return;

    final isSale = dealType.toLowerCase() == 'sale';
    final isApartment = propertyTypeCode.toLowerCase() == 'apartment';

    final data = <String, dynamic>{
      'ItemId': itemId,
      'PersonId': personId,
      'PropertyType': [{'Code': propertyTypeCode.toLowerCase()}],
      'DealType': dealType,
      'Title': title,
      'PostCode': postCode,
      'City': city,
      'CountryCode': 'AT',
      'Radius': (radiusKm * 1000).toInt(),
      'MinimumLivingArea': minLivingArea.toInt(),
      'MaximumLivingArea': maxLivingArea.toInt(),
      'MinimumLandArea': 0,
      'MaximumLandArea': 0,
      'MinimumNumberOfRooms': minRooms,
      'MaximumNumberOfRooms': maxRooms,
      'MinimumBuildingYear': minBuildingYear,
      'MaximumBuildingYear': maxBuildingYear,
      'IsWheelchairAccessible': isWheelchairAccessible,
      'MaximumDistanceHospital': maxDistanceHospital,
      'MaximumDistanceGroceryStore': maxDistanceGroceryStore,
      'MaximumDistancePublicTransport': maxDistancePublicTransport,
      if (isSale) ...{
        'MinimumSalePrice': minSalePrice ?? 0,
        'MaximumSalePrice': maxSalePrice ?? 0,
        'SalePriceCurrency': 'EUR',
      } else ...{
        'MinimumRentGross': minRentGross ?? 0,
        'MaximumRentGross': maxRentGross ?? 0,
        'RentGrossCurrency': 'EUR',
      },
      if (isApartment) ...{'HasLift': hasLift, 'HasParkingSpaces': null}
      else ...{'HasParkingSpaces': hasParkingSpaces, 'HasLift': null},
    };

    await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Update',
      body: {'EntityName': 'OfferSearchQuery', 'JsonString': jsonEncode(data)},
      headers: _headers(session.accessToken),
    );
  }

  Future<String?> saveSearchQuery({
    required String personId,
    required String title,
    required String postCode,
    required String city,
    required double radiusKm,
    required String dealType,
    required String propertyTypeCode,
    required double minLivingArea,
    required double maxLivingArea,
    required int minRooms,
    required int maxRooms,
    required int minBuildingYear,
    required int maxBuildingYear,
    bool isWheelchairAccessible = false,
    int? maxDistanceHospital,
    int? maxDistanceGroceryStore,
    int? maxDistancePublicTransport,
    bool? hasLift,
    bool? hasParkingSpaces,
    int? minSalePrice,
    int? maxSalePrice,
    int? minRentGross,
    int? maxRentGross,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final isSale = dealType.toLowerCase() == 'sale';
    final isApartment = propertyTypeCode.toLowerCase() == 'apartment';

    final payload = <String, dynamic>{
      'SaveOfferSearchQuery': true,
      'Type': 'Is-A-OfferSearch',
      'PersonId': personId,
      'PropertyType': [
        {'Code': propertyTypeCode.toLowerCase()},
      ],
      'DealType': dealType,
      'Title': title,
      'PostCode': postCode,
      'City': city,
      'Street': null,
      'HouseNumber': null,
      'CountryCode': 'AT',
      'Radius': (radiusKm * 1000).toInt(),
      'MinimumLivingArea': minLivingArea.toInt(),
      'MaximumLivingArea': maxLivingArea.toInt(),
      'MinimumLandArea': 0,
      'MaximumLandArea': 0,
      'MinimumNumberOfRooms': minRooms,
      'MaximumNumberOfRooms': maxRooms,
      'MinimumBuildingYear': minBuildingYear,
      'MaximumBuildingYear': maxBuildingYear,
      'IsWheelchairAccessible': isWheelchairAccessible,
      'MaximumDistanceHospital': maxDistanceHospital,
      'MaximumDistanceGroceryStore': maxDistanceGroceryStore,
      'MaximumDistancePublicTransport': maxDistancePublicTransport,
      'MessageCorrelationId': _uuid(),
    };

    if (isSale) {
      payload['MinimumSalePrice'] = minSalePrice ?? 0;
      payload['MaximumSalePrice'] = maxSalePrice ?? 0;
      payload['SalePriceCurrency'] = 'EUR';
    } else {
      payload['MinimumRentGross'] = minRentGross ?? 0;
      payload['MaximumRentGross'] = maxRentGross ?? 0;
      payload['RentGrossCurrency'] = 'EUR';
    }

    if (isApartment) {
      payload['HasLift'] = hasLift;
      payload['HasParkingSpaces'] = null;
    } else {
      payload['HasParkingSpaces'] = hasParkingSpaces;
      payload['HasLift'] = null;
    }

    final result = await _apiClient.postJson(
      url: '${_priceHubbleUrl}Query/SearchOffers',
      body: payload,
      headers: _headers(session.accessToken),
    );

    final body = result['body'] as Map<String, dynamic>? ?? {};
    return body['OfferSearchQueryId'] as String?;
  }

  Future<({double? lat, double? lng})> fetchGeocode(String address) async {
    final session = await _sessionCache.resolve();
    if (session == null) return (lat: null, lng: null);
    try {
      final result = await _apiClient.postJson(
        url: '${_apiClient.slsnBusinessUrl}GoogleQuery/GetGeoCode',
        body: {'Address': Uri.encodeComponent(address), 'Language': 'de'},
        headers: _headers(session.accessToken),
      );
      final results =
          ((result['body'] as Map<String, dynamic>?)?['Results'] as List?) ?? [];
      if (results.isEmpty) return (lat: null, lng: null);
      final first = results.first as Map<String, dynamic>;
      final loc = (first['geometry'] as Map<String, dynamic>?)?['location']
          as Map<String, dynamic>?;
      return (
        lat: (loc?['lat'] as num?)?.toDouble(),
        lng: (loc?['lng'] as num?)?.toDouble(),
      );
    } catch (_) {
      return (lat: null, lng: null);
    }
  }

  Future<DashboardAdvisorInfo?> fetchAdvisorInfo() async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    try {
      final connResponse = await _apiClient.postJson(
        url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetConnections',
        body: {
          'EntityName': 'Connection',
          'DataFilters': [
            {'PropertyName': 'ParentEntityName', 'Value': 'Person'},
            {'PropertyName': 'ChildEntityName', 'Value': 'Person'},
            {'PropertyName': 'ChildEntityID', 'Value': session.personId},
            {'PropertyName': 'Tags', 'Value': 'Customer-Of-Advisor'},
          ],
          'ExpandParent': false,
          'ExpandChild': false,
          'Fields': null,
          'IncludeConnection': false,
          'PageNumber': 0,
          'PageLimit': 100,
        },
        headers: _headers(session.accessToken),
      );
      final connResults =
          ((connResponse['body'] as Map<String, dynamic>?)?['Results'] as List?) ?? [];
      if (connResults.isEmpty) return null;
      final advisorPersonId =
          (connResults.first as Map<String, dynamic>)['ParentEntityID'] as String?;
      if (advisorPersonId == null || advisorPersonId.isEmpty) return null;

      final advResponse = await _apiClient.postJson(
        url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
        body: {
          'EntityName': 'AdvisorDenormalized',
          'Text':
              'select<ItemId,PersonId,Phone,ProposedUserId,DisplayName,Email,ProfileImageId,ColorCode,ManagerNr> from<AdvisorDenormalized> where<PersonId = __eql($advisorPersonId)>',
          'ExcludeCount': true,
        },
        headers: _headers(session.accessToken),
      );
      final advResults =
          ((advResponse['body'] as Map<String, dynamic>?)?['Results'] as List?) ?? [];
      if (advResults.isEmpty) return null;
      final d = advResults.first as Map<String, dynamic>;

      final colorCode = d['ColorCode'] as String?;
      int colorValue = 0xFF43B883;
      if (colorCode != null && colorCode.startsWith('#') && colorCode.length == 7) {
        colorValue = int.tryParse('FF${colorCode.substring(1)}', radix: 16) ?? colorValue;
      }

      return DashboardAdvisorInfo(
        isAvailable: true,
        displayName: d['DisplayName'] as String?,
        email: d['Email'] as String?,
        phone: d['Phone'] as String?,
        profileImageUrl: _apiClient.resolveProfileImageUrl(d['ProfileImageId'] as String?),
        avatarColorValue: colorValue,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _headers(String accessToken) => {
        'Authorization': 'bearer $accessToken',
        'Origin': _apiClient.originUrl,
      };

  static String _uuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
