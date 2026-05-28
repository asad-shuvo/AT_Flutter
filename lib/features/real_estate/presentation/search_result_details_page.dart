import 'package:filip_at_flutter/features/real_estate/data/offer_details.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _openUrl(String url) async {
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MoreVertSheet(
        hasInterestedUrl: details.url != null && details.url!.isNotEmpty,
        onRequestDossier: () async {
          Navigator.pop(context);
          final personId = await widget.repository.getPersonId();
          if (personId != null && details.offerId != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dossier request sent.')),
            );
          }
        },
        onIAmInterested: () {
          Navigator.pop(context);
          if (details.url != null) _openUrl(details.url!);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).pop(),
              onMoreVert: _details != null ? _showMoreVert : null,
            ),
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            Expanded(child: _buildBody(scheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }
    if (_error != null || _details == null) {
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
    return _DetailsContent(
      details: _details!,
      pageController: _pageController,
      currentPage: _currentPage,
      onPageChanged: (i) => setState(() => _currentPage = i),
      onMapTap: () => _openUrl(_details!.mapUrl),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, this.onMoreVert});

  final VoidCallback onBack;
  final VoidCallback? onMoreVert;

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
              'Search Result Details',
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
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

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.details,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onMapTap,
  });

  final OfferDetails details;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onMapTap;

  bool get _isApartment => details.propertyTypeCode?.toUpperCase() == 'APARTMENT';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
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
            _TitleSection(details: details),
            const SizedBox(height: 15),
            _DealTypeBadge(isForRent: details.isForRent),
            const SizedBox(height: 25),
            _ImageCarousel(
              imageUrls: details.imageUrls,
              isApartment: _isApartment,
              pageController: pageController,
              currentPage: currentPage,
              onPageChanged: onPageChanged,
            ),
            const SizedBox(height: 25),
            _PriceAndValuateRow(details: details),
            const SizedBox(height: 25),
            _MapAndDetailsRow(details: details, onMapTap: onMapTap),
            const SizedBox(height: 25),
            Divider(color: scheme.outlineVariant),
            if (details.description != null && details.description!.isNotEmpty) ...[
              const SizedBox(height: 25),
              _DescriptionSection(description: details.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.details});
  final OfferDetails details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.title != null)
          Text(
            details.title!,
            style: TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (details.processedAddress != null) ...[
          const SizedBox(height: 4),
          Text(
            details.processedAddress!,
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
    );
  }
}

class _DealTypeBadge extends StatelessWidget {
  const _DealTypeBadge({required this.isForRent});
  final bool isForRent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            isForRent ? 'Available for Rent' : 'Available for Sale',
            style: TextStyle(
              fontFamily: 'Calibri',
              fontSize: 13,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;
    final hasImages = imageUrls.isNotEmpty;

    Widget fallback() => Container(
          color: scheme.primary.withValues(alpha: 0.10),
          child: Icon(
            isApartment ? Icons.apartment_outlined : Icons.home_work_outlined,
            size: 64,
            color: scheme.primary,
          ),
        );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 250,
            width: double.infinity,
            child: hasImages
                ? PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemCount: imageUrls.length,
                    itemBuilder: (_, i) => Image.network(
                      imageUrls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback(),
                    ),
                  )
                : fallback(),
          ),
        ),
        if (hasImages && imageUrls.length > 1) ...[
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
                          ? scheme.primary
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

class _PriceAndValuateRow extends StatelessWidget {
  const _PriceAndValuateRow({required this.details});
  final OfferDetails details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.euro, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offer Price',
                    style: TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    details.priceLabel,
                    style: TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: scheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              'Valuate this Property',
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 13,
                color: scheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapAndDetailsRow extends StatelessWidget {
  const _MapAndDetailsRow({required this.details, required this.onMapTap});
  final OfferDetails details;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _MapCard(onTap: onMapTap)),
        const SizedBox(width: 16),
        Expanded(child: _PropertyStatsGrid(details: details)),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 32, color: Colors.white),
              SizedBox(height: 6),
              Text(
                'Map View',
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyStatsGrid extends StatelessWidget {
  const _PropertyStatsGrid({required this.details});
  final OfferDetails details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Divider(color: scheme.outlineVariant),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.calendar_today_outlined,
                label: 'Building Year',
                value: details.buildingYear?.toString(),
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.square_foot,
                label: 'Living Area',
                value: details.livingArea != null
                    ? '${_fmt(details.livingArea!)} m²'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.landscape_outlined,
                label: 'Land Area',
                value: details.landArea != null
                    ? '${_fmt(details.landArea!)} m²'
                    : null,
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.meeting_room_outlined,
                label: 'Total Rooms',
                value: details.numberOfRooms != null
                    ? _fmt(details.numberOfRooms!)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: scheme.outlineVariant),
      ],
    );
  }

  static String _fmt(num value) {
    if (value == value.truncate()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label, this.value});
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value ?? '—',
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Details',
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined, size: 22, color: scheme.primary),
            title: Text(
              'Request Dossier',
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                color: scheme.onSurface,
              ),
            ),
            onTap: onRequestDossier,
          ),
          if (hasInterestedUrl)
            ListTile(
              leading: Icon(Icons.thumb_up_outlined, size: 22, color: scheme.primary),
              title: Text(
                'I am Interested',
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
              onTap: onIAmInterested,
            ),
        ],
      ),
    );
  }
}
