import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/application/observation_controller.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/observe_property_details_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/property_form_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/contact_advisor_sheet.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/dossier_progress_sheet.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_card.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_command_card.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_empty_card.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_more_vert_sheet.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/dossier_web_view_page.dart';
import 'package:flutter/material.dart';

class ObservationTab extends StatefulWidget {
  const ObservationTab({
    super.key,
    required this.controller,
    required this.repository,
  });

  final ObservationController controller;
  final RealEstateRepository repository;

  @override
  State<ObservationTab> createState() => _ObservationTabState();
}

class _ObservationTabState extends State<ObservationTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.controller.load());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMore();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _onMoreVert(PropertyItem item) async {
    if (!mounted) return;
    final action = await showPropertyMoreVertSheet(
      context: context,
      item: item,
      source: PropertyListSource.observation,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case PropertyMoreVertAction.edit:
        await _openEditForm(item);
      case PropertyMoreVertAction.contactAdvisor:
        await _showContactAdvisor();
      case PropertyMoreVertAction.detailedView:
        await _openDetailedView(item);
      case PropertyMoreVertAction.delete:
        await _confirmDelete(item);
      case PropertyMoreVertAction.requestDossier:
        await _requestDossier(item);
      case PropertyMoreVertAction.observeAnother:
        break;
      case PropertyMoreVertAction.valuateAnother:
        break;
      case PropertyMoreVertAction.addToObserve:
        break;
      case PropertyMoreVertAction.toggleAgent:
        break;
    }
  }

  Future<void> _openEditForm(PropertyItem item) async {
    try {
      final formData = await widget.repository.fetchPropertyFormData(item.itemId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => PropertyFormPage(
            source: PropertyListSource.observation,
            repository: widget.repository,
            initialData: formData,
            onSaved: widget.controller.refresh,
          ),
        ),
      );
      if (mounted) widget.controller.refresh();
    } catch (_) {
      if (mounted) _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
    }
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

  void _openAddForm() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => PropertyFormPage(
          source: PropertyListSource.observation,
          repository: widget.repository,
          onSaved: widget.controller.refresh,
        ),
      ),
    );
  }

  void _openDetails(PropertyItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ObservePropertyDetailsPage(
          id: item.itemId,
          repository: widget.repository,
          observationController: widget.controller,
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
      if (mounted) _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
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
          _showSnackBar(context.l10n.tr('ANOTHER_PDF_GENERATION_IN_PROGRESS'));
          await Future.delayed(const Duration(seconds: 4));
          if (!mounted) return;
        }
        showDossierProgressSheet(context: context);
      } else {
        _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
      }
    } catch (_) {
      if (mounted) _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
    }
  }

  Future<void> _confirmDelete(PropertyItem item) async {
    final confirmed = await showDeleteConfirmSheet(context);
    if (!confirmed || !mounted) return;
    await widget.controller.deleteItem(item.itemId);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    if (ctrl.isInitialLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (ctrl.error != null && ctrl.items.isEmpty) {
      return Center(
        child: Text(
          'Failed to load. Pull down to retry.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: widget.controller.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + AppBottomNav.circleProtrusion + 16),
        itemCount: _itemCount(ctrl),
        itemBuilder: (context, index) => _buildItem(context, ctrl, index),
      ),
    );
  }

  int _itemCount(ObservationController ctrl) {
    final dataRows = ctrl.items.isEmpty ? 1 : ctrl.items.length;
    return 1 + dataRows + (ctrl.isLoadingMore ? 1 : 0);
  }

  Widget _buildItem(BuildContext context, ObservationController ctrl, int index) {
    if (index == 0) {
      return PropertyCommandCard(
        config: PropertyListConfig.observation,
        count: ctrl.totalCount,
        onAdd: _openAddForm,
      );
    }

    final dataIndex = index - 1;

    if (ctrl.items.isEmpty) {
      return const PropertyEmptyCard();
    }

    if (dataIndex < ctrl.items.length) {
      final item = ctrl.items[dataIndex];
      return PropertyCard(
        item: item,
        config: PropertyListConfig.observation,
        onTap: () => _openDetails(item),
        onMoreVert: () => _onMoreVert(item),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
