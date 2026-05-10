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
    this.email,
    this.phoneNumber,
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
  final String? email;
  final String? phoneNumber;
  final String? lastName;
  final String? proposedUserId;
  final String? managerNr;
  final int? totalContracts;
  final bool isSelected;

  Color get avatarColor => Color(avatarColorValue);

  String get fallbackInitial {
    final source = displayName.trim().isNotEmpty
        ? displayName.trim()
        : (lastName?.trim() ?? '');
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

  String? get resolvedProfileImageUrl {
    final value = profileImageUrl?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('//')) return 'https:$value';

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    return null;
  }

  bool get hasRenderableProfileImage => resolvedProfileImageUrl != null;

  ContractsHouseholdMember copyWith({
    String? personId,
    String? displayName,
    int? avatarColorValue,
    bool? isCurrentUser,
    String? customerId,
    String? profileImageUrl,
    String? email,
    String? phoneNumber,
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
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
