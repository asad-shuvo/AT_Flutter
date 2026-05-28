import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contracts_page.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HouseholdMembersPage extends StatefulWidget {
  const HouseholdMembersPage({
    super.key,
    required this.dashboardRepository,
    required this.contractsRepository,
    required this.notificationsRepository,
    required this.authSessionController,
    required this.appVersion,
    required this.syncNotificationService,
    required this.householdController,
    required this.isBusiness,
    required this.driveRepository,
    required this.userSessionCache,
    required this.realEstateRepository,
    this.profileRepository,
  });

  final DashboardRepository dashboardRepository;
  final ContractsRepository contractsRepository;
  final NotificationsRepository notificationsRepository;
  final AuthSessionController authSessionController;
  final String appVersion;
  final SyncNotificationService syncNotificationService;
  final HouseholdMemberFilterController householdController;
  final bool isBusiness;
  final DriveRepository driveRepository;
  final UserSessionCache userSessionCache;
  final RealEstateRepository realEstateRepository;
  final ProfileRepository? profileRepository;

  @override
  State<HouseholdMembersPage> createState() => _HouseholdMembersPageState();
}

class _HouseholdMembersPageState extends State<HouseholdMembersPage> {
  bool _isLeavingHousehold = false;

  @override
  void initState() {
    super.initState();
    if (!widget.householdController.isInitialized) {
      widget.householdController.ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(FilipIcons.back, color: Color(0xFF808080), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.tr(widget.isBusiness ? 'tns.business' : 'tns.household'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF666666),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E5E5)),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.householdController,
        builder: (context, _) {
          final members = widget.isBusiness
              ? widget.householdController.businessMembers
              : widget.householdController.householdMembers;

          if (widget.householdController.isLoading && members.isEmpty) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryRed,
                  ),
                ),
              ),
            );
          }

          if (members.isEmpty) {
            return Center(
              child: Text(
                l10n.tr('tns.noDataAddedYet'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  color: Color(0xFF9A9A9A),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              10,
              8,
              10,
              widget.isBusiness ? 12 : 90,
            ),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return _HouseholdMemberCard(
                member: member,
                showMeBadge: !widget.isBusiness,
                contractsLabel: _contractsAvailableLabel(
                  member.totalContracts ?? 0,
                  l10n,
                ),
                onContractsTap: () => _openContractsForMember(member),
              );
            },
          );
        },
      ),
      bottomNavigationBar: widget.isBusiness
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLeavingHousehold
                        ? null
                        : _handleLeaveHousehold,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryRed,
                      disabledBackgroundColor: const Color(0xFFDA7A86),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLeavingHousehold
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            l10n.tr('tns.leaveHousehold').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Calibri',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  String _contractsAvailableLabel(int totalContracts, AppLocalizations l10n) {
    final countLabel = _formatContractsCount(totalContracts);
    return '$countLabel ${l10n.tr('tns.contractsAvailable')}';
  }

  String _formatContractsCount(int value) {
    const words = <int, String>{
      0: 'Zero',
      1: 'One',
      2: 'Two',
      3: 'Three',
      4: 'Four',
      5: 'Five',
      6: 'Six',
      7: 'Seven',
      8: 'Eight',
      9: 'Nine',
    };
    return words[value] ?? value.toString();
  }

  void _openContractsForMember(ContractsHouseholdMember member) {
    final mode = widget.isBusiness
        ? ContractsHouseholdMode.business
        : ContractsHouseholdMode.household;

    final householdMembers = HouseholdMemberFilterController.setSelectionForAll(
      widget.householdController.copyHouseholdMembers(),
      false,
    );
    final businessMembers = HouseholdMemberFilterController.setSelectionForAll(
      widget.householdController.copyBusinessMembers(),
      false,
    );

    if (mode == ContractsHouseholdMode.household) {
      final index = householdMembers.indexWhere(
        (m) => m.personId == member.personId,
      );
      if (index != -1) {
        householdMembers[index] = householdMembers[index].copyWith(
          isSelected: true,
        );
      }
    } else {
      final index = businessMembers.indexWhere(
        (m) => m.personId == member.personId,
      );
      if (index != -1) {
        businessMembers[index] = businessMembers[index].copyWith(
          isSelected: true,
        );
      }
    }

    widget.householdController.applySelection(
      mode: mode,
      householdMembers: householdMembers,
      businessMembers: businessMembers,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContractsPage(
          contractsRepository: widget.contractsRepository,
          dashboardRepository: widget.dashboardRepository,
          notificationsRepository: widget.notificationsRepository,
          authSessionController: widget.authSessionController,
          appVersion: widget.appVersion,
          syncNotificationService: widget.syncNotificationService,
          householdController: widget.householdController,
          driveRepository: widget.driveRepository,
          userSessionCache: widget.userSessionCache,
          realEstateRepository: widget.realEstateRepository,
          profileRepository: widget.profileRepository,
        ),
      ),
    );
  }

  Future<void> _handleLeaveHousehold() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.tr('tns.leaveHouseholdBottomSheetTitle'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          content: Text(
            l10n.tr('tns.leaveHouseholdBottomSheetSubTitle'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.tr('tns.no')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.tr('tns.yes')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isLeavingHousehold = true;
    });

    try {
      await widget.contractsRepository.sendLeaveHouseholdEmail();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tr('tns.genericError'))));
    } finally {
      if (mounted) {
        setState(() {
          _isLeavingHousehold = false;
        });
      }
    }
  }
}

class _HouseholdMemberCard extends StatelessWidget {
  const _HouseholdMemberCard({
    required this.member,
    required this.showMeBadge,
    required this.contractsLabel,
    required this.onContractsTap,
  });

  final ContractsHouseholdMember member;
  final bool showMeBadge;
  final String contractsLabel;
  final VoidCallback onContractsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemberAvatar(member: member),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      FilipIcons.advisorMail,
                      size: 19,
                      color: Color(0xFF808080),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _displayOrDash(member.email),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      FilipIcons.advisorPhone,
                      size: 19,
                      color: Color(0xFF808080),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _displayOrDash(member.phoneNumber),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onContractsTap,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          contractsLabel,
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryRed,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ),
                    if (showMeBadge && member.isCurrentUser)
                      Container(
                        width: 54,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F0EF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          context.l10n.tr('tns.me').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15847B),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayOrDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final ContractsHouseholdMember member;

  @override
  Widget build(BuildContext context) {
    final imageUrl = member.resolvedProfileImageUrl;
    if (imageUrl != null) {
      return Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _MemberAvatarFallback(member: member);
          },
        ),
      );
    }

    return _MemberAvatarFallback(member: member);
  }
}

class _MemberAvatarFallback extends StatelessWidget {
  const _MemberAvatarFallback({required this.member});

  final ContractsHouseholdMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: member.avatarColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        member.fallbackInitial,
        style: const TextStyle(
          fontFamily: 'Calibri',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}
