import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:flutter/material.dart';

enum PropertyMoreVertAction {
  edit,
  observeAnother,
  valuateAnother,
  contactAdvisor,
  detailedView,
  delete,
  requestDossier,
  addToObserve,
  toggleAgent,
}

const _iconFont = 'filip_at_iconpack_29022024';
const _iconEdit = '';
const _iconContactAdvisor = '';
const _iconDetailedView = '';
const _iconDelete = '';
const _iconRequestDossier = '';
const _iconAddToObserve = '';
const _iconAgent = ''; // U+E95A

Future<PropertyMoreVertAction?> showPropertyMoreVertSheet({
  required BuildContext context,
  required PropertyItem item,
  required PropertyListSource source,
}) {
  return showModalBottomSheet<PropertyMoreVertAction>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => _MoreVertSheet(item: item, source: source),
  );
}

class _MoreVertSheet extends StatelessWidget {
  const _MoreVertSheet({required this.item, required this.source});

  final PropertyItem item;
  final PropertyListSource source;

  bool get _alreadyObserved =>
      item.tags.contains('Is-A-Observation') && item.tags.contains('Is-A-Valuation');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = _buildActions(l10n);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          _ActionRow(
            icon: actions[i].icon,
            label: actions[i].label,
            disabled: actions[i].disabled,
            onTap: actions[i].disabled ? null : () => Navigator.of(context).pop(actions[i].action),
          ),
          if (i < actions.length - 1)
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }

  List<_ActionConfig> _buildActions(AppLocalizations l10n) {
    if (source == PropertyListSource.search) {
      return [
        _ActionConfig(PropertyMoreVertAction.edit, _iconEdit, l10n.tr('editSearch')),
        _ActionConfig(
          PropertyMoreVertAction.toggleAgent,
          _iconAgent,
          item.isSearchAgentActive
              ? l10n.tr('deactivateSearchAgent')
              : l10n.tr('activateSearchAgent'),
        ),
        _ActionConfig(PropertyMoreVertAction.delete, _iconDelete, l10n.tr('deleteSearchAgent')),
      ];
    }
    if (source == PropertyListSource.observation) {
      return [
        _ActionConfig(PropertyMoreVertAction.edit, _iconEdit, l10n.tr('editProperty')),
        _ActionConfig(PropertyMoreVertAction.observeAnother, _iconAddToObserve, l10n.tr('tns.observeAnother')),
        _ActionConfig(PropertyMoreVertAction.contactAdvisor, _iconContactAdvisor, l10n.tr('contactAdvisor')),
        _ActionConfig(PropertyMoreVertAction.detailedView, _iconDetailedView, l10n.tr('detailedView')),
        _ActionConfig(PropertyMoreVertAction.delete, _iconDelete, l10n.tr('deleteProperty')),
        _ActionConfig(PropertyMoreVertAction.requestDossier, _iconRequestDossier, l10n.tr('requestDossier')),
      ];
    }
    return [
      _ActionConfig(PropertyMoreVertAction.edit, _iconEdit, l10n.tr('editProperty')),
      _ActionConfig(PropertyMoreVertAction.valuateAnother, _iconAddToObserve, l10n.tr('tns.valuateAnother')),
      _ActionConfig(PropertyMoreVertAction.requestDossier, _iconRequestDossier, l10n.tr('requestDossier')),
      _ActionConfig(PropertyMoreVertAction.contactAdvisor, _iconContactAdvisor, l10n.tr('contactAdvisor')),
      _ActionConfig(PropertyMoreVertAction.detailedView, _iconDetailedView, l10n.tr('detailedView')),
      _ActionConfig(
        PropertyMoreVertAction.addToObserve,
        _iconAddToObserve,
        _alreadyObserved ? l10n.tr('ALREADY_ADDED_TO_OVSERVE') : l10n.tr('addToObserve'),
        disabled: _alreadyObserved,
      ),
      _ActionConfig(PropertyMoreVertAction.delete, _iconDelete, l10n.tr('deleteProperty')),
    ];
  }
}

class _ActionConfig {
  const _ActionConfig(this.action, this.icon, this.label, {this.disabled = false});

  final PropertyMoreVertAction action;
  final String icon;
  final String label;
  final bool disabled;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.disabled,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const enabledIconColor = Color(0xFFA11C36);
    const enabledTextColor = Color(0xFF333333);
    const disabledColor = Color(0xFFCACACA);
    final iconColor = disabled ? disabledColor : enabledIconColor;
    final textColor = disabled ? disabledColor : enabledTextColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                icon,
                style: TextStyle(
                  fontFamily: _iconFont,
                  fontSize: 22,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showDeleteConfirmSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => const _DeleteConfirmSheet(),
  );
  return result ?? false;
}

class _DeleteConfirmSheet extends StatelessWidget {
  const _DeleteConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _iconDelete,
            style: const TextStyle(
              fontFamily: _iconFont,
              fontSize: 72,
              color: Color(0xFFD82034),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.tr('deleteRecord'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD82034),
                    side: const BorderSide(color: Color(0xFFD82034)),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    l10n.tr('cancel').toUpperCase(),
                    style: const TextStyle(fontFamily: 'Calibri', fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD82034),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    l10n.tr('confirm').toUpperCase(),
                    style: const TextStyle(fontFamily: 'Calibri', fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
