import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/data/search_result_item.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/search_result_details_page.dart';
import 'package:flutter/material.dart';

const _iconFont = 'filip_at_iconpack_29022024';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({
    super.key,
    required this.qid,
    required this.repository,
  });

  final String qid;
  final RealEstateRepository repository;

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

  static const _limit = 20;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _SearchResultHeader(onBack: () => Navigator.of(context).pop()),
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            if (!_isInitialLoading)
              _PropertyCountRow(count: _totalItems),
            Expanded(child: _buildBody(scheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_isInitialLoading) {
      return Center(
        child: CircularProgressIndicator(color: scheme.primary),
      );
    }

    if ((_error != null || _items.isEmpty) && !_isLoadingMore) {
      return Center(
        child: Text(
          'No search results found.',
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
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

class _SearchResultHeader extends StatelessWidget {
  const _SearchResultHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: scheme.onSurfaceVariant),
          ),
          Expanded(
            child: Text(
              'Search Result',
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCountRow extends StatelessWidget {
  const _PropertyCountRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            '',
            style: TextStyle(
              fontFamily: _iconFont,
              fontSize: 22,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Properties found ($count)',
            style: TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.item, required this.onTap});

  final SearchResultItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PropertyImage(item: item),
            _PropertyTitleSection(title: item.title, address: item.processedAddress),
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

  bool get _isApartment => item.propertyTypeCode?.toUpperCase() == 'APARTMENT';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(scheme),
              )
            : _fallback(scheme),
      ),
    );
  }

  Widget _fallback(ColorScheme scheme) => Container(
        color: scheme.primary.withValues(alpha: 0.10),
        child: Icon(
          _isApartment ? Icons.apartment_outlined : Icons.home_work_outlined,
          size: 64,
          color: scheme.primary,
        ),
      );
}

class _PropertyTitleSection extends StatelessWidget {
  const _PropertyTitleSection({this.title, this.address});

  final String? title;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (address != null) ...[
            const SizedBox(height: 4),
            Text(
              address!,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 13,
                color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 0,
              children: [
                if (item.numberOfRooms != null) ...[
                  Text('${_fmt(item.numberOfRooms!)} ROOMS', style: _detailStyle(scheme)),
                  _dot(scheme),
                ],
                if (item.livingArea != null) ...[
                  Text('${_fmt(item.livingArea!)} M²', style: _detailStyle(scheme)),
                  _dot(scheme),
                ],
                if (item.propertyTypeCode != null)
                  Text(item.propertyTypeCode!.toUpperCase(), style: _detailStyle(scheme)),
              ],
            ),
          ),
          Text(
            item.priceLabel,
            style: TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _detailStyle(ColorScheme scheme) => TextStyle(
        fontFamily: 'Calibri',
        fontSize: 12,
        color: scheme.onSurfaceVariant,
      );

  Widget _dot(ColorScheme scheme) => Text(
        ' · ',
        style: TextStyle(fontFamily: 'Calibri', fontSize: 12, color: scheme.outlineVariant),
      );

  static String _fmt(num value) {
    if (value == value.truncate()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
