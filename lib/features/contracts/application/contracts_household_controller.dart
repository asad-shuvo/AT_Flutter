import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:flutter/foundation.dart';

class ContractsHouseholdController extends ChangeNotifier {
  ContractsHouseholdController({
    required ContractsRepository contractsRepository,
  }) : _contractsRepository = contractsRepository;

  final ContractsRepository _contractsRepository;

  bool _isLoading = true;
  ContractsHouseholdMode _mode = ContractsHouseholdMode.household;
  List<ContractsHouseholdMember> _householdMembers =
      const <ContractsHouseholdMember>[];
  List<ContractsHouseholdMember> _businessMembers =
      const <ContractsHouseholdMember>[];

  bool get isLoading => _isLoading;
  ContractsHouseholdMode get mode => _mode;
  List<ContractsHouseholdMember> get householdMembers =>
      List<ContractsHouseholdMember>.unmodifiable(_householdMembers);
  List<ContractsHouseholdMember> get businessMembers =>
      List<ContractsHouseholdMember>.unmodifiable(_businessMembers);

  bool get isInitialized => _householdMembers.isNotEmpty;
  bool get hasBusinessMembers => _businessMembers.isNotEmpty;
  bool get shouldShowFilter =>
      _householdMembers.length > 1 || _businessMembers.isNotEmpty;

  List<ContractsHouseholdMember> get visibleMembers {
    return _mode == ContractsHouseholdMode.household
        ? householdMembers
        : businessMembers;
  }

  List<String> get selectedPersonIds {
    final members = _mode == ContractsHouseholdMode.household
        ? _householdMembers
        : _businessMembers;
    return members
        .where((member) => member.isSelected)
        .map((member) => member.personId)
        .toList(growable: false);
  }

  bool get canOpenAddContractForSelection {
    final selectedIds = selectedPersonIds;
    if (selectedIds.isEmpty) {
      return true;
    }
    if (selectedIds.length != 1) {
      return false;
    }

    final selectedId = selectedIds.first;
    return _householdMembers.any(
      (member) => member.personId == selectedId && member.isCurrentUser,
    );
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    // Preserve selection across notification-triggered reloads (NativeScript parity:
    // _selectedHouseholdData BehaviorSubject survives re-fetch and restores IsSelected).
    final bool isReload =
        _householdMembers.isNotEmpty || _businessMembers.isNotEmpty;
    final Set<String> savedHouseholdIds = isReload
        ? _householdMembers
            .where((m) => m.isSelected)
            .map((m) => m.personId)
            .toSet()
        : const <String>{};
    final Set<String> savedBusinessIds = isReload
        ? _businessMembers
            .where((m) => m.isSelected)
            .map((m) => m.personId)
            .toSet()
        : const <String>{};

    try {
      final householdData = await _contractsRepository.fetchHouseholdData();
      if (householdData != null) {
        if (isReload) {
          // Restore selection: current user always selected (NativeScript: isLoggedInUser → true).
          _householdMembers = householdData.householdMembers
              .map((m) => m.copyWith(
                    isSelected: m.isCurrentUser
                        ? true
                        : savedHouseholdIds.contains(m.personId),
                  ))
              .toList(growable: false);
          _businessMembers = householdData.businessMembers
              .map((m) => m.copyWith(
                    isSelected: savedBusinessIds.contains(m.personId),
                  ))
              .toList(growable: false);
        } else {
          _householdMembers = householdData.householdMembers;
          _businessMembers = householdData.businessMembers;
        }
      }
    } catch (_) {
      _householdMembers = const <ContractsHouseholdMember>[];
      _businessMembers = const <ContractsHouseholdMember>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool toggleVisibleMemberSelection(String personId) {
    final members = _mode == ContractsHouseholdMode.household
        ? _householdMembers
        : _businessMembers;
    final selectedCount = members.where((member) => member.isSelected).length;
    final selectedIndex =
        members.indexWhere((member) => member.personId == personId);
    if (selectedIndex == -1) {
      return true;
    }

    final currentMember = members[selectedIndex];
    if (currentMember.isSelected && selectedCount == 1) {
      return false;
    }

    if (_mode == ContractsHouseholdMode.household) {
      _businessMembers = _setSelection(_businessMembers, false);
      _householdMembers = _toggleSelection(_householdMembers, personId);
    } else {
      _householdMembers = _setSelection(_householdMembers, false);
      _businessMembers = _toggleSelection(_businessMembers, personId);
    }

    notifyListeners();
    return true;
  }

  void applySelection({
    required ContractsHouseholdMode mode,
    required List<ContractsHouseholdMember> householdMembers,
    required List<ContractsHouseholdMember> businessMembers,
  }) {
    _mode = mode;
    _householdMembers =
        List<ContractsHouseholdMember>.unmodifiable(householdMembers);
    _businessMembers =
        List<ContractsHouseholdMember>.unmodifiable(businessMembers);
    notifyListeners();
  }

  List<ContractsHouseholdMember> copyHouseholdMembers() {
    return _householdMembers
        .map((member) => member.copyWith())
        .toList(growable: false);
  }

  List<ContractsHouseholdMember> copyBusinessMembers() {
    return _businessMembers
        .map((member) => member.copyWith())
        .toList(growable: false);
  }

  static List<ContractsHouseholdMember> setSelectionForAll(
    List<ContractsHouseholdMember> members,
    bool isSelected,
  ) {
    return members
        .map((member) => member.copyWith(isSelected: isSelected))
        .toList(growable: false);
  }

  static List<ContractsHouseholdMember> ensureFirstSelected(
    List<ContractsHouseholdMember> members,
  ) {
    if (members.isEmpty || members.any((member) => member.isSelected)) {
      return members;
    }
    return List<ContractsHouseholdMember>.generate(members.length, (index) {
      return members[index].copyWith(isSelected: index == 0);
    }, growable: false);
  }

  static bool areAllSelected(List<ContractsHouseholdMember> members) {
    return members.isNotEmpty && members.every((member) => member.isSelected);
  }

  static bool hasAtLeastOneSelected(List<ContractsHouseholdMember> members) {
    return members.any((member) => member.isSelected);
  }

  List<ContractsHouseholdMember> _setSelection(
    List<ContractsHouseholdMember> members,
    bool isSelected,
  ) {
    return members
        .map((member) => member.copyWith(isSelected: isSelected))
        .toList(growable: false);
  }

  List<ContractsHouseholdMember> _toggleSelection(
    List<ContractsHouseholdMember> members,
    String personId,
  ) {
    return members
        .map((member) => member.personId == personId
            ? member.copyWith(isSelected: !member.isSelected)
            : member)
        .toList(growable: false);
  }
}
