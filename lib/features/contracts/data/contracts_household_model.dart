import 'package:flutter/material.dart';

enum ContractsHouseholdMode { household, business }

class ContractsHouseholdMember {
  const ContractsHouseholdMember({
    required this.personId,
    required this.displayName,
    required this.avatarColorValue,
    required this.isCurrentUser,
    this.customerId,
    this.profileImageUrl,
    this.lastName,
    this.proposedUserId,
    this.managerNr,
    this.totalContracts,
    this.isSelected = false,
  });

  final String personId;
  final String displayName;
  final int avatarColorValue;
  final bool isCurrentUser;
  final String? customerId;
  final String? profileImageUrl;
  final String? lastName;
  final String? proposedUserId;
  final String? managerNr;
  final int? totalContracts;
  final bool isSelected;

  Color get avatarColor => Color(avatarColorValue);

  String get fallbackInitial {
    final source = (lastName?.trim().isNotEmpty ?? false)
        ? lastName!.trim()
        : displayName.trim();
    if (source.isEmpty) {
      return '?';
    }
    return source[0].toUpperCase();
  }

  String get displayLastName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return lastName!.trim();
    }

    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return displayName.trim();
    }
    return parts.last;
  }

  bool get hasRenderableProfileImage =>
      profileImageUrl != null && profileImageUrl!.startsWith('http');

  ContractsHouseholdMember copyWith({
    String? personId,
    String? displayName,
    int? avatarColorValue,
    bool? isCurrentUser,
    String? customerId,
    String? profileImageUrl,
    String? lastName,
    String? proposedUserId,
    String? managerNr,
    int? totalContracts,
    bool? isSelected,
  }) {
    return ContractsHouseholdMember(
      personId: personId ?? this.personId,
      displayName: displayName ?? this.displayName,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      customerId: customerId ?? this.customerId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastName: lastName ?? this.lastName,
      proposedUserId: proposedUserId ?? this.proposedUserId,
      managerNr: managerNr ?? this.managerNr,
      totalContracts: totalContracts ?? this.totalContracts,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class ContractsHouseholdData {
  const ContractsHouseholdData({
    required this.currentPersonId,
    required this.currentCustomerId,
    required this.householdMembers,
    required this.businessMembers,
  });

  final String currentPersonId;
  final String currentCustomerId;
  final List<ContractsHouseholdMember> householdMembers;
  final List<ContractsHouseholdMember> businessMembers;
}
