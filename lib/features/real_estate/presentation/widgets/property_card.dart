import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:flutter/material.dart';

const _iconFont = 'filip_at_iconpack_29022024';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.item,
    required this.config,
    required this.onTap,
    required this.onMoreVert,
  });

  final PropertyItem item;
  final PropertyListConfig config;
  final VoidCallback onTap;
  final VoidCallback onMoreVert;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 8,
                top: 12,
                bottom: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PropertyThumbnail(
                    imageUrl: item.imageUrl,
                    propertyType: item.propertyType,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TitleRow(title: item.title, onMoreVert: onMoreVert),
                        if (item.address != null || item.city != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [item.address, item.city]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(', '),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 14,
                                color: Color(0xFF808080),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 4),
                        _BottomRow(item: item, config: config),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ],
        ),
      ),
    );
  }
}

class _PropertyThumbnail extends StatelessWidget {
  const _PropertyThumbnail({this.imageUrl, this.propertyType});

  final String? imageUrl;
  final PropertyTypeInfo? propertyType;

  static const String _snFont = 'SelectNetwork';

  int get _iconCode =>
      propertyType?.code?.toUpperCase() == 'APARTMENT' ? 0xEA09 : 0xEA08;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, st) => _buildIcon(),
              )
            : _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    return ColoredBox(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Text(
          String.fromCharCode(_iconCode),
          style: const TextStyle(
            fontFamily: _snFont,
            fontSize: 26,
            color: Color(0xFF808080),
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({this.title, required this.onMoreVert});

  final String? title;
  final VoidCallback onMoreVert;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title ?? '—',
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onMoreVert,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              Icons.more_vert,
              color: Color(0xFFB4B4B4),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.item, required this.config});

  final PropertyItem item;
  final PropertyListConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateLabel = l10n.tr(config.dateLabelKey);
    return Row(
      children: [
        Text(
          '$dateLabel ${_formatDate(item.createDate)}',
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 12,
            color: Color(0xFFB4B4B4),
          ),
        ),
        if (config.source == PropertyListSource.observation &&
            item.isMakeMeMovePriceGiven)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              String.fromCharCode(0xEA39),
              style: const TextStyle(
                fontFamily: _iconFont,
                fontSize: 14,
                color: Color(0xFFD82034),
              ),
            ),
          ),
        if (config.source == PropertyListSource.search &&
            item.isSearchAgentActive)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              String.fromCharCode(0xE95A),
              style: const TextStyle(
                fontFamily: _iconFont,
                fontSize: 16,
                color: Color(0xFFD82034),
              ),
            ),
          ),
        const Spacer(),
        Text(
          _priceLabel(item, config.source),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFA11C36),
          ),
        ),
      ],
    );
  }

  static String _priceLabel(PropertyItem item, PropertyListSource source) {
    switch (source) {
      case PropertyListSource.observation:
        return _formatCurrency(item.salePrice ?? 0);
      case PropertyListSource.valuation:
        final range = item.salePriceRange;
        if (range == null) return '€ 0';
        return '${_formatCurrency(range.lower)} - ${_formatCurrency(range.upper)}';
      case PropertyListSource.search:
        return '';
    }
  }

  static String _formatCurrency(double value) {
    if (value >= 1e9) return '€ ${(value / 1e9).toStringAsFixed(2)}B.';
    if (value >= 1e6) return '€ ${(value / 1e6).toStringAsFixed(2)}Mio.';
    if (value >= 1e3) return '€ ${(value / 1e3).toStringAsFixed(2)}Tsd.';
    return '€ ${value.toStringAsFixed(2)}';
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      return '$d.$m.${dt.year}';
    } catch (_) {
      return '—';
    }
  }
}
