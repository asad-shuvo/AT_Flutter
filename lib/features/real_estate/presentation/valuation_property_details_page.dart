import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_valuation_entry.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/property_form_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/dossier_web_view_page.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/contact_advisor_sheet.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/dossier_progress_sheet.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/price_line_chart.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_more_vert_sheet.dart';
import 'package:flutter/material.dart';

const _iconFont = 'filip_at_iconpack_29022024';

class ValuationPropertyDetailsPage extends StatefulWidget {
  const ValuationPropertyDetailsPage({
    super.key,
    required this.id,
    required this.repository,
  });

  final String id;
  final RealEstateRepository repository;

  @override
  State<ValuationPropertyDetailsPage> createState() =>
      _ValuationPropertyDetailsPageState();
}

class _ValuationPropertyDetailsPageState
    extends State<ValuationPropertyDetailsPage> {
  PropertyItem? _item;
  List<PropertyValuationEntry> _history = [];
  bool _isLoading = true;
  bool _isHistoryLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final item = await widget.repository.fetchPropertyById(widget.id);
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _isLoading = false;
          _error = 'Property not found.';
        });
        return;
      }
      setState(() {
        _item = item;
        _isLoading = false;
      });
      _loadHistory(item);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadHistory(PropertyItem item) async {
    setState(() => _isHistoryLoading = true);
    try {
      final history = await widget.repository.fetchPropertyValuationHistory(
        propertyId: item.itemId,
      );
      if (mounted) {
        setState(() {
          _history = history;
          _isHistoryLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _onMoreVert() async {
    final item = _item;
    if (item == null) return;
    final action = await showPropertyMoreVertSheet(
      context: context,
      item: item,
      source: PropertyListSource.valuation,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case PropertyMoreVertAction.edit:
        await _openEditForm(item);
      case PropertyMoreVertAction.valuateAnother:
        await _openValuateAnother();
      case PropertyMoreVertAction.requestDossier:
        await _requestDossier(item);
      case PropertyMoreVertAction.contactAdvisor:
        await _showContactAdvisor();
      case PropertyMoreVertAction.detailedView:
        await _openDetailedView(item);
      case PropertyMoreVertAction.addToObserve:
        await _addToObserve(item);
      case PropertyMoreVertAction.delete:
        await _confirmDelete(item);
      case PropertyMoreVertAction.observeAnother:
        break;
      case PropertyMoreVertAction.toggleAgent:
        break;
    }
  }

  Future<void> _openValuateAnother() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PropertyFormPage(
          source: PropertyListSource.valuation,
          repository: widget.repository,
          initialData: null,
          onSaved: () {},
        ),
      ),
    );
  }

  Future<void> _openEditForm(PropertyItem item) async {
    final formData = await widget.repository.fetchPropertyFormData(item.itemId);
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PropertyFormPage(
          source: PropertyListSource.valuation,
          repository: widget.repository,
          initialData: formData,
          onSaved: _load,
        ),
      ),
    );
  }

  Future<void> _showContactAdvisor() async {
    final data = await widget.repository.fetchAdvisorInfo();
    if (!mounted) return;
    showContactAdvisorSheet(
      context: context,
      advisor: data != null && data.isAvailable
          ? AdvisorInfo(
              displayName: data.displayName ?? '',
              title: context.l10n.tr('myFinancialAdvisor'),
              profileImageUrl: data.profileImageUrl,
              colorCode: Color(data.avatarColorValue),
              email: data.email,
              phone: data.phone,
            )
          : null,
      onChatTap: () {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(builder: (_) => const ChatPage()),
        );
      },
    );
  }

  Future<void> _openDetailedView(PropertyItem item) async {
    if (item.dossierId == null) {
      _showSnackBar('No dossier available for this property.');
      return;
    }
    try {
      final url = await widget.repository.fetchDossierShareLink(item.dossierId!);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        _showSnackBar('Could not load dossier link.');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DossierWebViewPage(url: url)),
      );
    } catch (_) {
      if (mounted) _showSnackBar('Something went wrong. Please try again.');
    }
  }

  Future<void> _requestDossier(PropertyItem item) async {
    if (item.dossierId == null) {
      _showSnackBar('No dossier available for this property.');
      return;
    }
    final personId = await widget.repository.getPersonId();
    if (personId == null || !mounted) return;
    try {
      final result = await widget.repository.requestDossierPdf(
        dossierId: item.dossierId!,
        personId: personId,
      );
      if (!mounted) return;
      if (result.success || result.alreadyInProgress) {
        if (result.alreadyInProgress) {
          _showSnackBar('Another PDF generation is already in progress.');
          await Future.delayed(const Duration(seconds: 4));
          if (!mounted) return;
        }
        showDossierProgressSheet(context: context);
      } else {
        _showSnackBar('Something went wrong. Please try again.');
      }
    } catch (_) {
      if (mounted) _showSnackBar('Something went wrong. Please try again.');
    }
  }

  Future<void> _addToObserve(PropertyItem item) async {
    final personId = await widget.repository.getPersonId();
    if (personId == null || !mounted) return;
    try {
      await widget.repository.updatePropertyTags(
        itemId: item.itemId,
        tags: [...item.tags, 'Is-A-Observation'],
        personId: personId,
      );
      if (mounted) {
        setState(() => _item = item.copyWith(tags: [...item.tags, 'Is-A-Observation']));
      }
    } catch (_) {
      if (mounted) _showSnackBar('Could not add to observation. Please try again.');
    }
  }

  Future<void> _confirmDelete(PropertyItem item) async {
    final confirmed = await showDeleteConfirmSheet(context);
    if (!confirmed || !mounted) return;
    try {
      await widget.repository.deleteProperty(
        propertyId: item.itemId,
        deletedFrom: 'Valuation',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _showSnackBar('Something went wrong. Please try again.');
    }
  }

  void _showPriceRangeInfo() {
    _showInfoSheet(
      context.l10n.tr('priceRange'),
      context.l10n.tr('priceRangeBody'),
    );
  }

  void _showConfidenceInfo() {
    _showInfoSheet(
      context.l10n.tr('valuationConfidence'),
      context.l10n.tr('valuationConfidenceBody'),
    );
  }

  void _showInfoSheet(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetCtx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  _iconInfo,
                  style: TextStyle(
                    fontFamily: _iconFont,
                    fontSize: 24,
                    color: Color(0xFF808080),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            _ValuationHeader(
              title: context.l10n.tr('tns.realEstateValuation'),
              onBack: () => Navigator.of(context).pop(),
              onMoreVert: _item != null ? _onMoreVert : null,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA11C36)),
      );
    }
    if (_error != null || _item == null) {
      return const Center(
        child: Text(
          'Could not load property details.',
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: Color(0xFF808080),
          ),
        ),
      );
    }
    return _ValuationContent(
      item: _item!,
      history: _history,
      isHistoryLoading: _isHistoryLoading,
      onPriceRangeInfoTap: _showPriceRangeInfo,
      onConfidenceInfoTap: _showConfidenceInfo,
    );
  }
}

class _ValuationHeader extends StatelessWidget {
  const _ValuationHeader({
    required this.title,
    required this.onBack,
    this.onMoreVert,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMoreVert;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF808080)),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
              ),
            ),
          ),
          IconButton(
            onPressed: onMoreVert,
            icon: Icon(
              Icons.more_vert,
              size: 22,
              color: onMoreVert != null
                  ? const Color(0xFF808080)
                  : const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuationContent extends StatelessWidget {
  const _ValuationContent({
    required this.item,
    required this.history,
    required this.isHistoryLoading,
    required this.onPriceRangeInfoTap,
    required this.onConfidenceInfoTap,
  });

  final PropertyItem item;
  final List<PropertyValuationEntry> history;
  final bool isHistoryLoading;
  final VoidCallback onPriceRangeInfoTap;
  final VoidCallback onConfidenceInfoTap;

  bool get _isRent => item.dealType?.toLowerCase() == 'rent';
  bool get _isApartment => item.propertyType?.code?.toUpperCase() == 'APARTMENT';

  PropertyValuationEntry? get _currentEntry {
    if (history.isEmpty) return null;
    final idx = history.length > 5 ? 5 : history.length - 1;
    return history[idx];
  }

  double? get _price {
    final e = _currentEntry;
    if (e == null) return item.salePrice;
    return (_isRent ? e.rentGross : e.salePrice) ?? item.salePrice;
  }

  SalePriceRange? get _priceRange {
    final e = _currentEntry;
    if (e == null) return item.salePriceRange;
    return _isRent ? e.rentGrossRange : e.salePriceRange;
  }

  String? get _confidence => _currentEntry?.confidence ?? '';

  static String _fmtCurrency(double? value) {
    if (value == null || value == 0) return '–';
    if (value >= 1e9) return '€ ${(value / 1e9).toStringAsFixed(2)}B.';
    if (value >= 1e6) return '€ ${(value / 1e6).toStringAsFixed(2)}Mio.';
    if (value >= 1e3) return '€ ${(value / 1e3).toStringAsFixed(2)}Tsd.';
    return '€ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? '—',
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF666666),
                    ),
                  ),
                  if (item.address != null || item.city != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [item.address, item.city]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' '),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 12,
                        color: Color(0xFF808080),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              width: double.infinity,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _InfoRowWithInfo(
                iconChar: _iconCoins,
                label: context.l10n.tr('priceRange'),
                onInfoTap: onPriceRangeInfoTap,
                child: _PriceRangeValue(
                  price: _price,
                  range: _priceRange,
                  formatCurrency: _fmtCurrency,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: _InfoRowWithInfo(
                iconChar: _iconConfidence,
                label: context.l10n.tr('valuationConfidence'),
                onInfoTap: onConfidenceInfoTap,
                child: _ConfidenceValue(confidence: _confidence),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            if (isHistoryLoading)
              const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA11C36),
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PriceLineChart(
                  entries: history,
                  isRent: _isRent,
                  isValuation: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFFF3F3F3),
        child: Icon(
          _isApartment ? Icons.apartment_outlined : Icons.home_work_outlined,
          size: 64,
          color: const Color(0xFFCCCCCC),
        ),
      );
}

class _InfoRowWithInfo extends StatelessWidget {
  const _InfoRowWithInfo({
    required this.iconChar,
    required this.label,
    required this.onInfoTap,
    required this.child,
  });

  final String iconChar;
  final String label;
  final VoidCallback onInfoTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFFFF5F6),
            child: Text(
              iconChar,
              style: const TextStyle(
                fontFamily: _iconFont,
                fontSize: 20,
                color: Color(0xFFA11C36),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 12,
                        color: Color(0xFF808080),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onInfoTap,
                      child: const Text(
                        _iconInfo,
                        style: TextStyle(
                          fontFamily: _iconFont,
                          fontSize: 12,
                          color: Color(0xFF6C6C6C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRangeValue extends StatelessWidget {
  const _PriceRangeValue({
    required this.price,
    required this.range,
    required this.formatCurrency,
  });

  final double? price;
  final SalePriceRange? range;
  final String Function(double?) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          formatCurrency(price),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFA11C36),
          ),
        ),
        if (range != null)
          Text(
            '(${formatCurrency(range!.lower)}  - ${formatCurrency(range!.upper)})',
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 12,
              color: Color(0xFF808080),
            ),
          ),
      ],
    );
  }
}

class _ConfidenceValue extends StatelessWidget {
  const _ConfidenceValue({required this.confidence});

  final String? confidence;

  bool get _isPoor => (confidence ?? '').toLowerCase() == 'poor';

  @override
  Widget build(BuildContext context) {
    return Text(
      (confidence ?? '').toUpperCase(),
      style: TextStyle(
        fontFamily: 'Calibri',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _isPoor ? const Color(0xFFA11C36) : const Color(0xFF15847B),
      ),
    );
  }
}

const _iconCoins = '';
const _iconConfidence = '';
const _iconInfo = '';
