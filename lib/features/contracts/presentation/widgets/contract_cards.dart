import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/contracts/data/insure_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_contract_model.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ContractsInvestmentContractCard extends StatelessWidget {
  const ContractsInvestmentContractCard({
    super.key,
    required this.contract,
    required this.currentPersonId,
    required this.ownerMembersByPersonId,
    required this.formatCurrency,
    required this.formatDate,
    required this.formatInvestmentType,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onTap,
  });

  final InvestmentContract contract;
  final String currentPersonId;
  final Map<String, ContractsHouseholdMember> ownerMembersByPersonId;
  final String Function(double value) formatCurrency;
  final String Function(DateTime? value) formatDate;
  final String Function(String? value) formatInvestmentType;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFilipSource = contract.source == 'FILIP';
    final iconBackground = isFilipSource
        ? const Color(0xFFEEEEEE)
        : const Color(0xFFFFF5F6);
    final iconColor = isFilipSource
        ? const Color(0xFF707070)
        : AppColors.primaryRed;
    final title = (contract.title == null || contract.title == '-')
        ? formatInvestmentType(contract.investmentType)
        : contract.title!;
    final subtitleType = formatInvestmentType(contract.investmentType);
    final amount = contract.displayAmount;
    final showMoreAction =
        (contract.source == 'FILIP' || contract.source == 'KVV') &&
        contract.personId == currentPersonId;
    final showDeleteAction = contract.source == 'FILIP';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      IconData(
                        contract.iconCodePoint,
                        fontFamily: 'filip_at_iconpack_29022024',
                      ),
                      size: 26,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Calibri',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subtitleType,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Calibri',
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: ContractTypeDot(),
                            ),
                            Text(
                              formatDate(contract.displayDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Calibri',
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showMoreAction)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: ContractMoreActionsButton(
                        showDeleteAction: showDeleteAction,
                        onEditTap: onEditTap,
                        onDeleteTap: onDeleteTap,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFBFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Row(
                children: [
                  ContractOwnerAvatars(
                    ownerPersonIds: _resolveOwnerPersonIds(),
                    ownerMembersByPersonId: ownerMembersByPersonId,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayPartnerName(contract.partnerName),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Calibri',
                        color: Color(0xFF777777),
                      ),
                    ),
                  ),
                  Text(
                    amount == null ? '-' : formatCurrency(amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Calibri',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _resolveOwnerPersonIds() {
    final personId = contract.personId?.trim();
    if (personId == null || personId.isEmpty) {
      return const <String>[];
    }
    return <String>[personId];
  }

  String _displayPartnerName(String? partnerName) {
    if (partnerName == null ||
        partnerName.trim().isEmpty ||
        partnerName == '-') {
      return '-';
    }
    return partnerName;
  }
}

class ContractsInsureContractCard extends StatelessWidget {
  const ContractsInsureContractCard({
    super.key,
    required this.contract,
    required this.currentPersonId,
    required this.ownerMembersByPersonId,
    required this.formatCurrency,
    required this.formatDate,
    required this.formatType,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onTap,
    this.endDatePrefix,
  });

  final InsureContract contract;
  final String currentPersonId;
  final Map<String, ContractsHouseholdMember> ownerMembersByPersonId;
  final String Function(double value) formatCurrency;
  final String Function(DateTime? value) formatDate;
  final String Function(String? value) formatType;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onTap;
  final String? endDatePrefix;

  @override
  Widget build(BuildContext context) {
    final isFilipSource = contract.source == 'FILIP';
    final iconBackground = isFilipSource
        ? const Color(0xFFEEEEEE)
        : const Color(0xFFFFF5F6);
    final iconColor = isFilipSource
        ? const Color(0xFF707070)
        : AppColors.primaryRed;
    final title = (contract.title == null || contract.title == '-')
        ? formatType(contract.type)
        : contract.title!;
    final showMoreAction = contract.personId == currentPersonId;
    final showDeleteAction = contract.source == 'FILIP';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      IconData(
                        contract.iconCodePoint,
                        fontFamily: 'filip_at_iconpack_29022024',
                      ),
                      size: 26,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Calibri',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                formatType(contract.type),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Calibri',
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: ContractTypeDot(),
                            ),
                            Text(
                              endDatePrefix == null
                                  ? formatDate(contract.endDate)
                                  : '$endDatePrefix: ${formatDate(contract.endDate)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Calibri',
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showMoreAction)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: ContractMoreActionsButton(
                        showDeleteAction: showDeleteAction,
                        onEditTap: onEditTap,
                        onDeleteTap: onDeleteTap,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFBFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Row(
                children: [
                  ContractOwnerAvatars(
                    ownerPersonIds: _resolveOwnerPersonIds(),
                    ownerMembersByPersonId: ownerMembersByPersonId,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayPartnerName(contract.partnerName),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Calibri',
                        color: Color(0xFF777777),
                      ),
                    ),
                  ),
                  Text(
                    contract.grossPremium == null
                        ? '-'
                        : formatCurrency(contract.grossPremium!),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Calibri',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _resolveOwnerPersonIds() {
    final owners = contract.insuredPersons
        .map((personId) => personId.trim())
        .where((personId) => personId.isNotEmpty)
        .toList(growable: false);
    if (owners.isNotEmpty) {
      return owners;
    }
    final personId = contract.personId?.trim();
    if (personId == null || personId.isEmpty) {
      return const <String>[];
    }
    return <String>[personId];
  }

  String _displayPartnerName(String? partnerName) {
    if (partnerName == null ||
        partnerName.trim().isEmpty ||
        partnerName == '-') {
      return '-';
    }
    return partnerName;
  }
}

class ContractMoreActionsButton extends StatelessWidget {
  const ContractMoreActionsButton({
    super.key,
    required this.showDeleteAction,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final bool showDeleteAction;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  Future<void> _openActionsSheet(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ContractActionSheetItem(
                  icon: const IconData(
                    0xE969,
                    fontFamily: 'filip_at_iconpack_29022024',
                  ),
                  label: l10n.tr('tns.edit'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onEditTap();
                  },
                ),
                if (showDeleteAction)
                  const Divider(height: 1, color: Color(0xFFE6E6E6)),
                if (showDeleteAction)
                  ContractActionSheetItem(
                    icon: const IconData(
                      0xE9F9,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    label: l10n.tr('tns.delete'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDeleteTap();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      onPressed: () => _openActionsSheet(context),
      icon: const Icon(Icons.more_vert, size: 24, color: Color(0xFF9C9C9C)),
    );
  }
}

class ContractActionSheetItem extends StatelessWidget {
  const ContractActionSheetItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppColors.primaryRed),
            const SizedBox(width: 18),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 20,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractTypeDot extends StatelessWidget {
  const ContractTypeDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFB6B6B6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class ContractOwnerAvatars extends StatelessWidget {
  const ContractOwnerAvatars({
    super.key,
    required this.ownerPersonIds,
    required this.ownerMembersByPersonId,
  });

  final List<String> ownerPersonIds;
  final Map<String, ContractsHouseholdMember> ownerMembersByPersonId;

  @override
  Widget build(BuildContext context) {
    if (ownerPersonIds.isEmpty) {
      return const ContractOwnerAvatar(member: null, fallbackInitial: '?');
    }

    const maxVisibleAvatars = 3;
    const avatarSize = 24.0;
    const overlapStep = 18.0;
    final visibleCount = ownerPersonIds.length > maxVisibleAvatars
        ? maxVisibleAvatars
        : ownerPersonIds.length;
    final stackWidth = avatarSize + ((visibleCount - 1) * overlapStep);

    return SizedBox(
      width: stackWidth,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(visibleCount, (index) {
          final personId = ownerPersonIds[index];
          final member = ownerMembersByPersonId[personId];
          final fallbackInitial = member?.fallbackInitial ?? '?';
          return Positioned(
            left: index * overlapStep,
            child: ContractOwnerAvatar(
              member: member,
              fallbackInitial: fallbackInitial,
            ),
          );
        }),
      ),
    );
  }
}

class ContractOwnerAvatar extends StatelessWidget {
  const ContractOwnerAvatar({
    super.key,
    required this.member,
    required this.fallbackInitial,
  });

  final ContractsHouseholdMember? member;
  final String fallbackInitial;

  @override
  Widget build(BuildContext context) {
    final imageUrl = member?.resolvedProfileImageUrl;
    if (imageUrl != null) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return ContractOwnerAvatarFallback(
              color: member?.avatarColor ?? const Color(0xFFD82034),
              fallbackInitial: fallbackInitial,
            );
          },
        ),
      );
    }

    return ContractOwnerAvatarFallback(
      color: member?.avatarColor ?? const Color(0xFFD82034),
      fallbackInitial: fallbackInitial,
    );
  }
}

class ContractOwnerAvatarFallback extends StatelessWidget {
  const ContractOwnerAvatarFallback({
    super.key,
    required this.color,
    required this.fallbackInitial,
  });

  final Color color;
  final String fallbackInitial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackInitial,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'Calibri',
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
