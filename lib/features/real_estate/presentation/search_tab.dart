import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/application/search_query_controller.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/search_query_form_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/search_result_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_card.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_command_card.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_empty_card.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/property_more_vert_sheet.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/search_agent_sheets.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({
    super.key,
    required this.controller,
    required this.repository,
  });

  final SearchQueryController controller;
  final RealEstateRepository repository;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
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

  void _openAddForm() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => SearchQueryFormPage(
          repository: widget.repository,
          onSaved: widget.controller.refresh,
        ),
      ),
    );
  }

  Future<void> _onMoreVert(PropertyItem item) async {
    if (!mounted) return;
    final action = await showPropertyMoreVertSheet(
      context: context,
      item: item,
      source: PropertyListSource.search,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case PropertyMoreVertAction.edit:
        await _openEditForm(item);
      case PropertyMoreVertAction.toggleAgent:
        await _onToggleAgent(item);
      case PropertyMoreVertAction.delete:
        await _confirmDelete(item);
      default:
        break;
    }
  }

  Future<void> _onToggleAgent(PropertyItem item) async {
    if (!mounted) return;
    if (item.isSearchAgentActive) {
      await showDeactivateAgentSheet(
        context: context,
        onDeactivate: () => _doToggleAgent(item, activate: false),
      );
    } else {
      await showActivateAgentSheet(
        context: context,
        repository: widget.repository,
        onActivate: () => _doToggleAgent(item, activate: true),
      );
    }
  }

  Future<void> _doToggleAgent(PropertyItem item, {required bool activate}) async {
    try {
      await widget.repository.toggleSearchAgent(
        itemId: item.itemId,
        activate: activate,
      );
      if (mounted) widget.controller.refresh();
    } catch (_) {
      if (mounted) _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
    }
  }

  Future<void> _openEditForm(PropertyItem item) async {
    try {
      final formData = await widget.repository.fetchSearchQueryById(item.itemId);
      if (!mounted) return;
      if (formData == null) {
        _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => SearchQueryFormPage(
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

  Future<void> _confirmDelete(PropertyItem item) async {
    final confirmed = await showDeleteConfirmSheet(context);
    if (!confirmed || !mounted) return;
    try {
      await widget.controller.deleteItem(item.itemId);
    } catch (_) {
      if (mounted) _showSnackBar(context.l10n.tr('SOMETHING_WENT_WRONG'));
    }
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

  int _itemCount(SearchQueryController ctrl) {
    final dataRows = ctrl.items.isEmpty ? 1 : ctrl.items.length;
    return 1 + dataRows + (ctrl.isLoadingMore ? 1 : 0);
  }

  Widget _buildItem(BuildContext context, SearchQueryController ctrl, int index) {
    if (index == 0) {
      return PropertyCommandCard(
        config: PropertyListConfig.search,
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
        config: PropertyListConfig.search,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SearchResultPage(
              qid: item.itemId,
              repository: widget.repository,
              isAgentActive: item.isSearchAgentActive,
              dealType: item.dealType ?? 'sale',
            ),
          ),
        ),
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
