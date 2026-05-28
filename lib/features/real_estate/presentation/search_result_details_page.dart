import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/offer_details.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _iconFontPrimary = 'filip_at_iconpack_29022024';
const _iconFontSN = 'SelectNetwork';

// NS codepoints (Dart unicode escapes — safe from Write stripping)
const _iconOfferPrice   = ''; // n-icon filip_at_iconpack
const _iconBuildingYear = ''; // n-icon filip_at_iconpack
const _iconLivingArea   = ''; // sn-icon SelectNetwork
const _iconLandArea     = ''; // sn-icon SelectNetwork
const _iconTotalRooms   = ''; // n-icon filip_at_iconpack
const _iconDealBadge    = ''; // sn-icon SelectNetwork

const _iconBoxBg = Color(0xFFFFF5F6);

class SearchResultDetailsPage extends StatefulWidget {
  const SearchResultDetailsPage({
    super.key,
    required this.qid,
    required this.id,
    required this.repository,
  });

  final String qid;
  final String id;
  final RealEstateRepository repository;

  @override
  State<SearchResultDetailsPage> createState() =>
      _SearchResultDetailsPageState();
}

class _SearchResultDetailsPageState extends State<SearchResultDetailsPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  OfferDetails? _details;
  bool _isLoading = true;
  String? _error;
  bool _isValuating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final details = await widget.repository.fetchOfferDetails(widget.id);
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onValuate() async {
    final details = _details;
    if (details?.offerId == null || _isValuating) return;
    setState(() => _isValuating = true);
    try {
      final data = await widget.repository.fetchOfferValuation(details!.offerId!);
      if (!mounted) return;
      setState(() => _isValuating = false);
      if (data == null) {
        _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (sheetCtx) => _ValuatePropertySheet(
          details: details,
          valuationData: data,
          onAddToValuate: () async {
            Navigator.of(sheetCtx).pop();
            await _doAddToValuate(details);
          },
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isValuating = false);
        _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
      }
    }
  }

  Future<void> _doAddToValuate(OfferDetails details) async {
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    try {
      await widget.repository.addToValuation(
        offerId: details.offerId!,
        address: details.processedAddress ?? '',
        language: lang,
      );
      if (mounted) {
        _showSnackBar(context.l10n.tr('valuationPropertySuccessfullyaddedMsg'));
      }
    } catch (_) {
      if (mounted) _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showMoreVert() {
    final details = _details;
    if (details == null) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) => _MoreVertSheet(
        hasInterestedUrl: details.url != null && details.url!.isNotEmpty,
        onRequestDossier: () {
          Navigator.of(sheetCtx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.tr('requestDossier'))),
          );
        },
        onIAmInterested: () {
          Navigator.of(sheetCtx).pop();
          if (details.url != null) _openUrl(details.url!);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l10n.tr('searchResultDetails'),
              onBack: () => Navigator.of(context).pop(),
              onMoreVert: _details != null ? _showMoreVert : null,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }
    if (_error != null || _details == null) {
      return Center(
        child: Text(
          context.l10n.tr('errorOccurred'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: Color(0xFF808080),
          ),
        ),
      );
    }
    return _DetailsContent(
      details: _details!,
      pageController: _pageController,
      currentPage: _currentPage,
      onPageChanged: (i) => setState(() => _currentPage = i),
      onMapTap: () => _openUrl(_details!.mapUrl),
      onValuate: _onValuate,
      isValuating: _isValuating,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onBack,
    this.onMoreVert,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMoreVert;

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
              title,
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
            icon: Icon(
              Icons.more_vert,
              size: 22,
              color: onMoreVert != null
                  ? const Color(0xFF555555)
                  : const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.details,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onMapTap,
    required this.onValuate,
    required this.isValuating,
  });

  final OfferDetails details;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onMapTap;
  final VoidCallback onValuate;
  final bool isValuating;

  bool get _isApartment =>
      details.propertyTypeCode?.toUpperCase() == 'APARTMENT';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + address
            if (details.title != null)
              Text(
                details.title!,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            if (details.processedAddress != null) ...[
              const SizedBox(height: 4),
              Text(
                details.processedAddress!,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 13,
                  color: Color(0xFF808080),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Deal type badge
            _DealTypeBadge(isForRent: details.isForRent, l10n: l10n),
            const SizedBox(height: 20),

            // Image carousel + thumbnails
            _ImageCarousel(
              imageUrls: details.imageUrls,
              isApartment: _isApartment,
              pageController: pageController,
              currentPage: currentPage,
              onPageChanged: onPageChanged,
            ),
            const SizedBox(height: 20),

            // Offer price
            _OfferPriceRow(details: details, l10n: l10n),
            const SizedBox(height: 16),

            // Valuate button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: isValuating ? null : onValuate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(color: AppColors.primaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: isValuating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryRed,
                        ),
                      )
                    : Text(
                        l10n.tr('valuateThisProperty').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.primaryRed,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Map view (full width)
            _MapCard(onTap: onMapTap, l10n: l10n),
            const SizedBox(height: 20),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 20),

            // Stats 2×2
            _StatsGrid(details: details, l10n: l10n),
            const SizedBox(height: 20),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            // Property description
            if (details.description != null &&
                details.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DescriptionSection(
                description: details.description!,
                l10n: l10n,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Deal type badge ───────────────────────────────────────────────────────────

class _DealTypeBadge extends StatelessWidget {
  const _DealTypeBadge({required this.isForRent, required this.l10n});

  final bool isForRent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _iconBoxBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Text(
            _iconDealBadge,
            style: TextStyle(
              fontFamily: _iconFontSN,
              fontSize: 20,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isForRent
                ? l10n.tr('availableForRent')
                : l10n.tr('availableForSale'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 13,
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image carousel ────────────────────────────────────────────────────────────

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({
    required this.imageUrls,
    required this.isApartment,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<String> imageUrls;
  final bool isApartment;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          color: const Color(0xFFF0F0F0),
          child: Icon(
            isApartment ? Icons.apartment_outlined : Icons.home_work_outlined,
            size: 64,
            color: AppColors.primaryRed,
          ),
        );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: imageUrls.isEmpty
                ? fallback()
                : PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemCount: imageUrls.length,
                    itemBuilder: (_, i) => Image.network(
                      imageUrls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback(),
                    ),
                  ),
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 65,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: currentPage == i
                          ? AppColors.primaryRed
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(
                      imageUrls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Offer price ───────────────────────────────────────────────────────────────

class _OfferPriceRow extends StatelessWidget {
  const _OfferPriceRow({required this.details, required this.l10n});

  final OfferDetails details;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _iconBoxBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Text(
              _iconOfferPrice,
              style: TextStyle(
                fontFamily: _iconFontPrimary,
                fontSize: 22,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('offerPrice'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 12,
                color: Color(0xFF808080),
              ),
            ),
            Text(
              details.priceLabel,
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
    );
  }
}

// ── Map card ──────────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  const _MapCard({required this.onTap, required this.l10n});

  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: const Color(0xFFD4B8B8),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.tr('mapView').toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats 2×2 grid ────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.details, required this.l10n});

  final OfferDetails details;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatItem(
                iconChar: _iconBuildingYear,
                iconFont: _iconFontPrimary,
                label: l10n.tr('buildingYear'),
                value: details.buildingYear?.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                iconChar: _iconLivingArea,
                iconFont: _iconFontSN,
                label: l10n.tr('livingArea'),
                value: details.livingArea != null
                    ? '${_fmt(details.livingArea!)}m²'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                iconChar: _iconLandArea,
                iconFont: _iconFontSN,
                label: l10n.tr('landArea'),
                value: details.landArea != null
                    ? '${_fmt(details.landArea!)}m²'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                iconChar: _iconTotalRooms,
                iconFont: _iconFontPrimary,
                label: l10n.tr('totalRooms'),
                value: details.numberOfRooms != null
                    ? _fmt(details.numberOfRooms!)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _fmt(num value) {
    if (value == value.truncate()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.iconChar,
    required this.iconFont,
    required this.label,
    this.value,
  });

  final String iconChar;
  final String iconFont;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _iconBoxBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              iconChar,
              style: TextStyle(
                fontFamily: iconFont,
                fontSize: 22,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
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
                value ?? '—',
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Description ───────────────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.description,
    required this.l10n,
  });

  final String description;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('propertyDetailsHeader'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: Color(0xFF333333),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── Valuate property sheet ────────────────────────────────────────────────────

const _iconValuateHeader = ''; // filip_at_iconpack U+E9A6 — injected via PS
const _iconConfidence    = ''; // filip_at_iconpack U+E9D0 — injected via PS

class _ValuatePropertySheet extends StatefulWidget {
  const _ValuatePropertySheet({
    required this.details,
    required this.valuationData,
    required this.onAddToValuate,
  });

  final OfferDetails details;
  final OfferValuationData valuationData;
  final VoidCallback onAddToValuate;

  @override
  State<_ValuatePropertySheet> createState() => _ValuatePropertySheetState();
}

class _ValuatePropertySheetState extends State<_ValuatePropertySheet> {
  bool _isAdding = false;

  Color _confidenceColor(String? c) {
    switch (c?.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFF4CAF50);
      case 'MEDIUM':
        return const Color(0xFF66BB6A);
      case 'LOW':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFF808080);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = widget.details;
    final v = widget.valuationData;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  const Text(
                    _iconValuateHeader,
                    style: TextStyle(
                      fontFamily: _iconFontPrimary,
                      fontSize: 24,
                      color: Color(0xFF808080),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.tr('valuateProperty'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Property image
              if (d.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Image.network(
                      d.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Icon(
                          Icons.home_work_outlined,
                          size: 48,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(
                      Icons.home_work_outlined,
                      size: 48,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Title + address
              if (d.title != null)
                Text(
                  d.title!,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              if (d.processedAddress != null) ...[
                const SizedBox(height: 3),
                Text(
                  d.processedAddress!,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 13,
                    color: Color(0xFF808080),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Offer price row
              _SheetStatRow(
                iconChar: _iconOfferPrice,
                iconFont: _iconFontPrimary,
                label: l10n.tr('offerPrice'),
                value: v.priceRangeLabel,
                valueColor: AppColors.primaryRed,
              ),
              const SizedBox(height: 12),

              // Confidence row
              _SheetStatRow(
                iconChar: _iconConfidence,
                iconFont: _iconFontPrimary,
                label: l10n.tr('valuationConfidence'),
                value: v.confidence?.toUpperCase() ?? '—',
                valueColor: _confidenceColor(v.confidence),
              ),
              const SizedBox(height: 24),

              // ADD TO VALUATE button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isAdding
                      ? null
                      : () {
                          setState(() => _isAdding = true);
                          widget.onAddToValuate();
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    side: const BorderSide(color: AppColors.primaryRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryRed,
                          ),
                        )
                      : Text(
                          l10n.tr('addToValuate').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.primaryRed,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetStatRow extends StatelessWidget {
  const _SheetStatRow({
    required this.iconChar,
    required this.iconFont,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String iconChar;
  final String iconFont;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _iconBoxBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              iconChar,
              style: TextStyle(
                fontFamily: iconFont,
                fontSize: 22,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── More-vert sheet ───────────────────────────────────────────────────────────

class _MoreVertSheet extends StatelessWidget {
  const _MoreVertSheet({
    required this.hasInterestedUrl,
    required this.onRequestDossier,
    required this.onIAmInterested,
  });

  final bool hasInterestedUrl;
  final VoidCallback onRequestDossier;
  final VoidCallback onIAmInterested;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRequestDossier,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 22,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    l10n.tr('requestDossier'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 15,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasInterestedUrl)
            InkWell(
              onTap: onIAmInterested,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_outlined,
                      size: 22,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      l10n.tr('iAmInterested'),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 15,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
