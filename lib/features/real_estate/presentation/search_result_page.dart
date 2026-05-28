import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/data/search_result_item.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/search_query_form_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/search_result_details_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/search_agent_sheets.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

const _iconFont = 'filip_at_iconpack_29022024';
const _iconSearch = '';
const _iconEdit = '';
const _iconSort = '';
const _iconAgent = '';

enum _SortOption {
  priceAsc,   // PRICE_ASCENDING  — lowest to highest
  priceDesc,  // PRICE_DESCENDING — highest to lowest
  dateDesc,   // DATE_ASCENDING   — newest to oldest (default)
  dateAsc,    // DATE_DESCENDING  — oldest to newest
}

extension _SortOptionExt on _SortOption {
  String l10nKey() {
    switch (this) {
      case _SortOption.priceAsc:  return 'PRICE_ASCENDING';
      case _SortOption.priceDesc: return 'PRICE_DESCENDING';
      case _SortOption.dateDesc:  return 'DATE_ASCENDING';
      case _SortOption.dateAsc:   return 'DATE_DESCENDING';
    }
  }

  List<Map<String, String>> toOrderBy(String dealType) {
    final priceField = dealType == 'rent' ? 'rentGross' : 'salePrice';
    switch (this) {
      case _SortOption.priceAsc:
        return [{'Field': priceField, 'Direction': 'asc'}];
      case _SortOption.priceDesc:
        return [{'Field': priceField, 'Direction': 'desc'}];
      case _SortOption.dateDesc:
        return [{'Field': 'startDate', 'Direction': 'desc'}];
      case _SortOption.dateAsc:
        return [{'Field': 'startDate', 'Direction': 'asc'}];
    }
  }
}

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({
    super.key,
    required this.qid,
    required this.repository,
    this.isAgentActive = false,
    this.dealType = 'sale',
  });

  final String qid;
  final RealEstateRepository repository;
  final bool isAgentActive;
  final String dealType;

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final _scrollController = ScrollController();

  List<SearchResultItem> _items = [];
  int _totalItems = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;
  int _offset = 0;
  late bool _isAgentActive;
  _SortOption _currentSort = _SortOption.dateDesc;

  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _isAgentActive = widget.isAgentActive;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
      _offset = 0;
    });
    try {
      final result = await widget.repository.fetchSearchResults(
        queryId: widget.qid,
        offset: 0,
        limit: _limit,
        orderBy: _currentSort.toOrderBy(widget.dealType),
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalItems = result.totalItems;
        _hasMore = result.items.length >= _limit;
        _offset = result.items.length;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await widget.repository.fetchSearchResults(
        queryId: widget.qid,
        offset: _offset,
        limit: _limit,
        orderBy: _currentSort.toOrderBy(widget.dealType),
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _hasMore = result.items.length >= _limit;
        _offset += result.items.length;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openEditSearch() async {
    final data = await widget.repository.fetchSearchQueryById(widget.qid);
    if (!mounted) return;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('errorOccurred'))),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchQueryFormPage(
          repository: widget.repository,
          initialData: data,
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) => _SortSheet(
        currentSort: _currentSort,
        onSelected: (sort) {
          Navigator.of(sheetCtx).pop();
          if (sort != _currentSort) {
            setState(() => _currentSort = sort);
            _load();
          }
        },
      ),
    );
  }

  void _showAgentSheet() {
    if (_isAgentActive) {
      _showDeactivateAgentSheet();
    } else {
      _showActivateAgentSheet();
    }
  }

  void _showActivateAgentSheet() {
    showActivateAgentSheet(
      context: context,
      repository: widget.repository,
      onActivate: () => _toggleAgent(activate: true),
    );
  }

  void _showDeactivateAgentSheet() {
    showDeactivateAgentSheet(
      context: context,
      onDeactivate: () => _toggleAgent(activate: false),
    );
  }

  Future<void> _toggleAgent({required bool activate}) async {
    setState(() => _isAgentActive = activate);
    try {
      await widget.repository.toggleSearchAgent(
        itemId: widget.qid,
        activate: activate,
      );
    } catch (_) {
      if (mounted) setState(() => _isAgentActive = !activate);
    }
  }

  void _onMoreVert() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoreVertItem(
              iconChar: _iconEdit,
              label: l10n.tr('editSearch'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _openEditSearch();
              },
            ),
            _MoreVertItem(
              iconChar: _iconSort,
              label: l10n.tr('searchSorting'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _showSortSheet();
              },
            ),
            _MoreVertItem(
              iconChar: _iconAgent,
              label: _isAgentActive
                  ? l10n.tr('deactivateSearchAgent')
                  : l10n.tr('activateSearchAgent'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _showAgentSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _SearchResultHeader(
              onBack: () => Navigator.of(context).pop(),
              onMoreVert: _onMoreVert,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            if (!_isInitialLoading) _PropertyCountRow(count: _totalItems),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if ((_error != null || _items.isEmpty) && !_isLoadingMore) {
      return Center(
        child: Text(
          context.l10n.tr('noSearchResultFound'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: Color(0xFF808080),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryRed,
              ),
            ),
          );
        }
        final item = _items[index];
        return _SearchResultCard(
          item: item,
          onTap: () {
            if (item.offerId != null && item.offerId!.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SearchResultDetailsPage(
                    qid: widget.qid,
                    id: item.offerId!,
                    repository: widget.repository,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SearchResultHeader extends StatelessWidget {
  const _SearchResultHeader({required this.onBack, required this.onMoreVert});

  final VoidCallback onBack;
  final VoidCallback onMoreVert;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF555555),
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.tr('searchResult'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
              ),
            ),
          ),
          IconButton(
            onPressed: onMoreVert,
            icon: const Icon(
              Icons.more_vert,
              size: 22,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Property count row ────────────────────────────────────────────────────────

class _PropertyCountRow extends StatelessWidget {
  const _PropertyCountRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text(
            _iconSearch,
            style: TextStyle(
              fontFamily: _iconFont,
              fontSize: 22,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${context.l10n.tr('propertyFound')} ($count)',
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

// ── More-vert menu item ───────────────────────────────────────────────────────

class _MoreVertItem extends StatelessWidget {
  const _MoreVertItem({
    required this.iconChar,
    required this.label,
    required this.onTap,
  });

  final String iconChar;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(
              iconChar,
              style: const TextStyle(
                fontFamily: _iconFont,
                fontSize: 20,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 15,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort sheet ────────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.currentSort, required this.onSelected});

  final _SortOption currentSort;
  final ValueChanged<_SortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Text(
                  _iconSort,
                  style: TextStyle(
                    fontFamily: _iconFont,
                    fontSize: 22,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.tr('searchSorting'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          for (final opt in _SortOption.values) ...[
            InkWell(
              onTap: () => onSelected(opt),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tr(opt.l10nKey()),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 15,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                    if (opt == currentSort)
                      const Icon(Icons.check, size: 20, color: AppColors.primaryRed),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


// ── Result card ───────────────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.item, required this.onTap});

  final SearchResultItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD2D2D2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PropertyImage(item: item),
            _PropertyTitleSection(
              title: item.title,
              address: item.processedAddress,
            ),
            _PropertyDetailsSection(item: item),
          ],
        ),
      ),
    );
  }
}

class _PropertyImage extends StatelessWidget {
  const _PropertyImage({required this.item});

  final SearchResultItem item;

  bool get _isApartment =>
      item.propertyTypeCode?.toUpperCase() == 'APARTMENT';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFFF0F0F0),
        child: Icon(
          _isApartment ? Icons.apartment_outlined : Icons.home_work_outlined,
          size: 64,
          color: AppColors.primaryRed,
        ),
      );
}

class _PropertyTitleSection extends StatelessWidget {
  const _PropertyTitleSection({this.title, this.address});

  final String? title;
  final String? address;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (address != null) ...[
            const SizedBox(height: 4),
            Text(
              address!,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                color: Color(0xFF808080),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _PropertyDetailsSection extends StatelessWidget {
  const _PropertyDetailsSection({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 0,
              children: [
                if (item.numberOfRooms != null) ...[
                  Text('${_fmt(item.numberOfRooms!)} ROOMS', style: _detailStyle),
                  _dot,
                ],
                if (item.livingArea != null) ...[
                  Text('${_fmt(item.livingArea!)} M²', style: _detailStyle),
                  _dot,
                ],
                if (item.propertyTypeCode != null)
                  Text(item.propertyTypeCode!.toUpperCase(), style: _detailStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.priceLabel,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA11C36),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _detailStyle = TextStyle(
    fontFamily: 'Calibri',
    fontSize: 12,
    color: Color(0xFF666666),
  );

  static const Widget _dot = Text(
    ' · ',
    style: TextStyle(fontFamily: 'Calibri', fontSize: 12, color: Color(0xFF666666)),
  );

  static String _fmt(num value) {
    if (value == value.truncate()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
