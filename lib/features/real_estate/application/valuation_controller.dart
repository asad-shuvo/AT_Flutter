import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:flutter/foundation.dart';

class ValuationController extends ChangeNotifier {
  ValuationController({required RealEstateRepository repository})
      : _repository = repository;

  final RealEstateRepository _repository;

  List<PropertyItem> items = [];
  int totalCount = 0;
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  bool hasMore = false;
  String? error;

  int _currentPage = 0;
  String? _personId;

  Future<void> load() async {
    final personId = await _repository.getPersonId();
    if (personId == null) return;
    _personId = personId;
    _currentPage = 0;
    isInitialLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchProperties(
        tag: PropertyListConfig.valuation.tag,
        personId: personId,
        pageNumber: 0,
      );
      items = result.items;
      totalCount = result.totalCount;
      hasMore = result.items.length >= 30;
      _currentPage = hasMore ? 1 : 0;
    } catch (e) {
      error = e.toString();
      items = [];
    } finally {
      isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || _personId == null) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.fetchProperties(
        tag: PropertyListConfig.valuation.tag,
        personId: _personId!,
        pageNumber: _currentPage,
        excludeCount: true,
      );
      _currentPage++;
      items = [...items, ...result.items];
      hasMore = result.items.length >= 30;
    } catch (_) {
      // Keep existing items on load-more failure.
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => load();

  Future<void> deleteItem(String itemId) async {
    await _repository.deleteProperty(
      propertyId: itemId,
      deletedFrom: 'Valuation',
    );
    items = items.where((i) => i.itemId != itemId).toList();
    totalCount = totalCount > 0 ? totalCount - 1 : 0;
    notifyListeners();
  }

  Future<void> addToObserve(String itemId) async {
    final personId = _personId;
    if (personId == null) return;

    await _repository.updatePropertyTags(
      itemId: itemId,
      tags: ['Is-A-Observation', 'Is-A-Valuation'],
      personId: personId,
    );
    items = items.map((i) {
      if (i.itemId != itemId) return i;
      final merged = {...i.tags, 'Is-A-Observation', 'Is-A-Valuation'}.toList();
      return i.copyWith(tags: merged);
    }).toList();
    notifyListeners();
  }
}
