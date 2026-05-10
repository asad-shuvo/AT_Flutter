import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ContractsHouseholdFilterSheetResult {
  const ContractsHouseholdFilterSheetResult({
    required this.mode,
    required this.householdMembers,
    required this.businessMembers,
  });

  final ContractsHouseholdMode mode;
  final List<ContractsHouseholdMember> householdMembers;
  final List<ContractsHouseholdMember> businessMembers;
}

Future<ContractsHouseholdFilterSheetResult?> showContractsHouseholdFilterSheet(
  BuildContext context, {
  required ContractsHouseholdMode initialMode,
  required List<ContractsHouseholdMember> initialHouseholdMembers,
  required List<ContractsHouseholdMember> initialBusinessMembers,
}) {
  return showModalBottomSheet<ContractsHouseholdFilterSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return ContractsHouseholdFilterSheet(
        initialMode: initialMode,
        initialHouseholdMembers: initialHouseholdMembers,
        initialBusinessMembers: initialBusinessMembers,
      );
    },
  );
}

class ContractsHouseholdMemberFilterBar extends StatelessWidget {
  const ContractsHouseholdMemberFilterBar({
    super.key,
    required this.controller,
    required this.onMemberTap,
    required this.onArrowTap,
  });

  final HouseholdMemberFilterController controller;
  final ValueChanged<String> onMemberTap;
  final VoidCallback onArrowTap;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return Container(
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E5E5)),
            bottom: BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          ),
        ),
      );
    }

    if (!controller.shouldShowFilter) {
      return const SizedBox.shrink();
    }

    final members = controller.visibleMembers;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5)),
          bottom: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: List.generate(members.length, (i) {
                  final member = members[i];
                  final label = member.isCurrentUser
                      ? context.l10n.tr('tns.me')
                      : member.displayLastName;
                  return GestureDetector(
                    onTap: () => onMemberTap(member.personId),
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: member.isSelected
                            ? const Color(0xFFFFF5F6)
                            : const Color(0xFFF4F4F4),
                        border: Border.all(
                          color: member.isSelected
                              ? AppColors.primaryRed
                              : const Color(0xFFD2D2D2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Row(
                        children: [
                          _FilterMemberAvatar(member: member, size: 37),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 56),
                            child: Text(
                              label.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Calibri',
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Container(
            width: 50,
            height: double.infinity,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: InkWell(
              onTap: onArrowTap,
              child: const Center(
                child: Icon(
                  SelectNetworkIcons.arrowDown,
                  size: 22,
                  color: Color(0xFF808080),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContractsHouseholdFilterSheet extends StatefulWidget {
  const ContractsHouseholdFilterSheet({
    super.key,
    required this.initialMode,
    required this.initialHouseholdMembers,
    required this.initialBusinessMembers,
  });

  final ContractsHouseholdMode initialMode;
  final List<ContractsHouseholdMember> initialHouseholdMembers;
  final List<ContractsHouseholdMember> initialBusinessMembers;

  @override
  State<ContractsHouseholdFilterSheet> createState() =>
      _ContractsHouseholdFilterSheetState();
}

class _ContractsHouseholdFilterSheetState
    extends State<ContractsHouseholdFilterSheet> {
  late ContractsHouseholdMode _mode;
  late List<ContractsHouseholdMember> _householdMembers;
  late List<ContractsHouseholdMember> _businessMembers;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialBusinessMembers.isEmpty
        ? ContractsHouseholdMode.household
        : widget.initialMode;
    _householdMembers = widget.initialHouseholdMembers;
    _businessMembers = widget.initialBusinessMembers;
  }

  bool get _isHouseholdMode => _mode == ContractsHouseholdMode.household;

  List<ContractsHouseholdMember> get _visibleMembers {
    return _isHouseholdMode ? _householdMembers : _businessMembers;
  }

  bool get _isAllSelected =>
      HouseholdMemberFilterController.areAllSelected(_householdMembers);

  bool get _canApply =>
      HouseholdMemberFilterController.hasAtLeastOneSelected(_visibleMembers);

  void _switchMode(ContractsHouseholdMode mode) {
    if (_mode == mode) return;

    setState(() {
      _mode = mode;
      if (_isHouseholdMode) {
        _businessMembers = HouseholdMemberFilterController.setSelectionForAll(
          _businessMembers,
          false,
        );
        _householdMembers = HouseholdMemberFilterController.ensureFirstSelected(
          _householdMembers,
        );
      } else {
        _householdMembers = HouseholdMemberFilterController.setSelectionForAll(
          _householdMembers,
          false,
        );
        _businessMembers = HouseholdMemberFilterController.ensureFirstSelected(
          _businessMembers,
        );
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _householdMembers = HouseholdMemberFilterController.setSelectionForAll(
        _householdMembers,
        !_isAllSelected,
      );
      _businessMembers = HouseholdMemberFilterController.setSelectionForAll(
        _businessMembers,
        false,
      );
    });
  }

  void _toggleMember(String personId) {
    setState(() {
      if (_isHouseholdMode) {
        _businessMembers = HouseholdMemberFilterController.setSelectionForAll(
          _businessMembers,
          false,
        );
        _householdMembers = _householdMembers
            .map(
              (member) => member.personId == personId
                  ? member.copyWith(isSelected: !member.isSelected)
                  : member,
            )
            .toList(growable: false);
      } else {
        _householdMembers = HouseholdMemberFilterController.setSelectionForAll(
          _householdMembers,
          false,
        );
        _businessMembers = _businessMembers
            .map(
              (member) => member.personId == personId
                  ? member.copyWith(isSelected: !member.isSelected)
                  : member,
            )
            .toList(growable: false);
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      ContractsHouseholdFilterSheetResult(
        mode: _mode,
        householdMembers: _householdMembers,
        businessMembers: _businessMembers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: 540,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0B8C0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SheetModeTab(
                          label:
                              '${l10n.tr('tns.household')} (${_householdMembers.length})',
                          isActive: _isHouseholdMode,
                          onTap: () =>
                              _switchMode(ContractsHouseholdMode.household),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: widget.initialBusinessMembers.isNotEmpty
                            ? _SheetModeTab(
                                label:
                                    '${l10n.tr('tns.business')} (${_businessMembers.length})',
                                isActive: !_isHouseholdMode,
                                onTap: () =>
                                    _switchMode(ContractsHouseholdMode.business),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isHouseholdMode) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        l10n.tr('tns.multipleSelection'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Calibri',
                          color: Color(0xFF666666),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleSelectAll,
                        child: Row(
                          children: [
                            Text(
                              l10n.tr('tns.selectAll'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Calibri',
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isAllSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 22,
                              color: AppColors.primaryRed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  itemCount: _visibleMembers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFEAEAEA)),
                  itemBuilder: (context, index) {
                    final member = _visibleMembers[index];
                    return InkWell(
                      onTap: () => _toggleMember(member.personId),
                      child: SizedBox(
                        height: 70,
                        child: Row(
                          children: [
                            _FilterMemberAvatar(member: member, size: 42),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                member.isCurrentUser && _isHouseholdMode
                                    ? '${member.displayName} (${l10n.tr('tns.me')})'
                                    : member.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Calibri',
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            if (member.isSelected)
                              const Icon(
                                Icons.done,
                                size: 22,
                                color: AppColors.primaryRed,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canApply ? _apply : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD8D8D8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.tr('tns.showContracts'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Calibri',
                        fontWeight: FontWeight.w700,
                      ),
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

class _FilterMemberAvatar extends StatelessWidget {
  const _FilterMemberAvatar({required this.member, required this.size});

  final ContractsHouseholdMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = member.resolvedProfileImageUrl;
    if (imageUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _FilterMemberAvatarFallback(member: member, size: size);
          },
        ),
      );
    }

    return _FilterMemberAvatarFallback(member: member, size: size);
  }
}

class _FilterMemberAvatarFallback extends StatelessWidget {
  const _FilterMemberAvatarFallback({required this.member, required this.size});

  final ContractsHouseholdMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: member.avatarColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          member.fallbackInitial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontFamily: 'Calibri',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SheetModeTab extends StatelessWidget {
  const _SheetModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Calibri',
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
