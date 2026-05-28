import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/application/observation_controller.dart';
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
const _iconTrendUp = '';
const _iconCoins = '';
const _iconBell = '';
const _iconInfo = '';

class ObservePropertyDetailsPage extends StatefulWidget {
  const ObservePropertyDetailsPage({
    super.key,
    required this.id,
    required this.repository,
    this.observationController,
  });

  final String id;
  final RealEstateRepository repository;
  final ObservationController? observationController;

  @override
  State<ObservePropertyDetailsPage> createState() =>
      _ObservePropertyDetailsPageState();
}

class _ObservePropertyDetailsPageState
    extends State<ObservePropertyDetailsPage> {
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
      source: PropertyListSource.observation,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case PropertyMoreVertAction.edit:
        await _openEditForm(item);
      case PropertyMoreVertAction.observeAnother:
        await _openObserveAnother();
      case PropertyMoreVertAction.valuateAnother:
        break;
      case PropertyMoreVertAction.contactAdvisor:
        await _showContactAdvisor();
      case PropertyMoreVertAction.detailedView:
        await _openDetailedView(item);
      case PropertyMoreVertAction.requestDossier:
        await _requestDossier(item);
      case PropertyMoreVertAction.delete:
        await _confirmDelete(item);
      case PropertyMoreVertAction.addToObserve:
        break;
      case PropertyMoreVertAction.toggleAgent:
        break;
    }
  }

  Future<void> _openObserveAnother() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PropertyFormPage(
          source: PropertyListSource.observation,
          repository: widget.repository,
          initialData: null,
          onSaved: () {},
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

  Future<void> _openEditForm(PropertyItem item) async {
    final formData = await widget.repository.fetchPropertyFormData(item.itemId);
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PropertyFormPage(
          source: PropertyListSource.observation,
          repository: widget.repository,
          initialData: formData,
          onSaved: _load,
        ),
      ),
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

  Future<void> _confirmDelete(PropertyItem item) async {
    final confirmed = await showDeleteConfirmSheet(context);
    if (!confirmed || !mounted) return;
    try {
      await widget.observationController?.deleteItem(item.itemId);
      await widget.repository.deleteProperty(
        propertyId: item.itemId,
        deletedFrom: 'Observation',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _showSnackBar('Something went wrong. Please try again.');
    }
  }

  Future<void> _onMovePriceToggled(bool value) async {
    final item = _item;
    if (item == null) return;

    if (value) {
      final price = await _showSetMovePriceSheet();
      if (price == null) return;
      try {
        await widget.repository.updateMakeMovePrice(
          itemId: item.itemId,
          price: price,
          isGiven: true,
        );
        if (mounted) setState(() => _item = item.withMakeMovePrice(price));
      } catch (_) {
        if (mounted) _showSnackBar('Could not save move price. Please try again.');
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.tr('setMovePrice')),
          content: const Text('Are you sure you want to remove your move price?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.l10n.tr('confirm'),
                style: const TextStyle(color: Color(0xFFD82034)),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await widget.repository.updateMakeMovePrice(
          itemId: item.itemId,
          price: null,
          isGiven: false,
        );
        if (mounted) setState(() => _item = item.withMakeMovePrice(null));
      } catch (_) {
        if (mounted) _showSnackBar('Could not remove move price. Please try again.');
      }
    }
  }

  Future<double?> _showSetMovePriceSheet() {
    final controller = TextEditingController();
    return showModalBottomSheet<double>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final hasValue = controller.text.trim().isNotEmpty;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        _iconCoins,
                        style: const TextStyle(
                          fontFamily: _iconFont,
                          fontSize: 28,
                          color: Color(0xFF808080),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        ctx.l10n.tr('setMovePrice'),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ctx.l10n.tr('setPropertyPrice'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 13,
                      color: Color(0xFF808080),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Price (€)',
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 12,
                      color: Color(0xFF808080),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setSheetState(() {}),
                    style: const TextStyle(fontFamily: 'Calibri', fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '${ctx.l10n.tr('enterPrice')} (€)',
                      hintStyle: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        color: Color(0xFFBBBBBB),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFA11C36)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52 + MediaQuery.of(sheetCtx).padding.bottom,
                  child: ElevatedButton(
                    onPressed: hasValue
                        ? () {
                            final val = double.tryParse(
                              controller.text
                                  .replaceAll(',', '')
                                  .replaceAll(' ', ''),
                            );
                            Navigator.of(sheetCtx).pop(val);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasValue
                          ? const Color(0xFFD82034)
                          : const Color(0xFFE8AEB4),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE8AEB4),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(sheetCtx).padding.bottom,
                      ),
                    ),
                    child: Text(
                      ctx.l10n.tr('confirm').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMovePriceInfoSheet() {
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
                Text(
                  _iconInfo,
                  style: const TextStyle(
                    fontFamily: _iconFont,
                    fontSize: 24,
                    color: Color(0xFF808080),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  sheetCtx.l10n.tr('setMovePrice'),
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
              sheetCtx.l10n.tr('tns.setMovePriceInfo'),
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            _PageHeader(
              title: context.l10n.tr('tns.observationProperty'),
              onBack: () => Navigator.of(context).pop(),
              onMoreVert: _item != null ? _onMoreVert : null,
            ),
            Expanded(child: _buildBody(scheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: scheme.primary),
      );
    }
    if (_error != null || _item == null) {
      return Center(
        child: Text(
          'Could not load property details.',
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return _ObservationContent(
      item: _item!,
      history: _history,
      isHistoryLoading: _isHistoryLoading,
      onMovePriceToggled: _onMovePriceToggled,
      onMovePriceInfoTap: _showMovePriceInfoSheet,
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.onBack,
    this.onMoreVert,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMoreVert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: scheme.onSurfaceVariant),
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
              color: onMoreVert != null ? scheme.onSurfaceVariant : scheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservationContent extends StatelessWidget {
  const _ObservationContent({
    required this.item,
    required this.history,
    required this.isHistoryLoading,
    required this.onMovePriceToggled,
    required this.onMovePriceInfoTap,
  });

  final PropertyItem item;
  final List<PropertyValuationEntry> history;
  final bool isHistoryLoading;
  final Future<void> Function(bool) onMovePriceToggled;
  final VoidCallback onMovePriceInfoTap;

  bool get _isRent => item.dealType?.toLowerCase() == 'rent';

  double? get _marketPrice {
    if (history.isNotEmpty) {
      final idx = history.length > 5 ? 5 : history.length - 1;
      final e = history[idx];
      final v = _isRent ? e.rentGross : e.salePrice;
      if (v != null && v > 0) return v;
    }
    return item.salePrice;
  }

  bool get _isApartment => item.propertyType?.code?.toUpperCase() == 'APARTMENT';

  static String _fmtCurrency(double? value) {
    if (value == null || value == 0) return '–';
    if (value >= 1e9) return '€ ${(value / 1e9).toStringAsFixed(2)}B.';
    if (value >= 1e6) return '€ ${(value / 1e6).toStringAsFixed(2)}Mio.';
    if (value >= 1e3) return '€ ${(value / 1e3).toStringAsFixed(2)}Tsd.';
    return '€ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          color: scheme.surface,
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
                      errorBuilder: (_, _, _) => _imageFallback(scheme),
                    )
                  : _imageFallback(scheme),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _InfoRow(
                iconCode: _iconTrendUp,
                label: context.l10n.tr('currentMarketPlace'),
                value: _fmtCurrency(_marketPrice),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: _InfoRow(
                iconCode: _iconCoins,
                label: context.l10n.tr('purchasePrice'),
                value: _fmtCurrency(item.purchasePrice),
              ),
            ),
            _MovePriceSection(
              item: item,
              onToggled: onMovePriceToggled,
              formatCurrency: _fmtCurrency,
              onInfoTap: onMovePriceInfoTap,
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
                  isValuation: false,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(ColorScheme scheme) => Container(
        color: const Color(0xFFF3F3F3),
        child: Icon(
          _isApartment ? Icons.apartment_outlined : Icons.home_work_outlined,
          size: 64,
          color: const Color(0xFFCCCCCC),
        ),
      );
}

class _MovePriceSection extends StatelessWidget {
  const _MovePriceSection({
    required this.item,
    required this.onToggled,
    required this.formatCurrency,
    required this.onInfoTap,
  });

  final PropertyItem item;
  final Future<void> Function(bool) onToggled;
  final String Function(double?) formatCurrency;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final isOn = item.isMakeMeMovePriceGiven;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFF3F3F3),
          child: Row(
            children: [
              Text(
                context.l10n.tr('setMovePrice').toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 12,
                  color: Color(0xFF808080),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onInfoTap,
                child: const Text(
                  _iconInfo,
                  style: TextStyle(
                    fontFamily: _iconFont,
                    fontSize: 14,
                    color: Color(0xFF808080),
                  ),
                ),
              ),
              const Spacer(),
              Switch(
                value: isOn,
                onChanged: onToggled,
                activeThumbColor: const Color(0xFFA11C36),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: isOn
                    ? const Color(0xFFFFF5F6)
                    : const Color(0xFFF3F3F3),
                child: Text(
                  _iconBell,
                  style: TextStyle(
                    fontFamily: _iconFont,
                    fontSize: 20,
                    color: isOn
                        ? const Color(0xFFA11C36)
                        : const Color(0xFF808080),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isOn
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCurrency(item.makeMeMovePrice),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                          Text(
                            context.l10n.tr('yourWishedPrice'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 12,
                              color: Color(0xFF808080),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.tr('turnOn'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                          Text(
                            context.l10n.tr('getNotificationAlert'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 12,
                              color: Color(0xFF808080),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.iconCode,
    required this.label,
    required this.value,
  });

  final String iconCode;
  final String label;
  final String value;

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
              iconCode,
              style: const TextStyle(
                fontFamily: _iconFont,
                fontSize: 20,
                color: Color(0xFFA11C36),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 12,
                  color: Color(0xFF808080),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA11C36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
