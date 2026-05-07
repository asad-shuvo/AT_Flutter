class DashboardOverviewSummary {
  const DashboardOverviewSummary({
    required this.totalFixedAsset,
    required this.totalInvestment,
    required this.totalLiabilities,
    required this.totalMonthlyPremium,
  });

  final double? totalFixedAsset;
  final double? totalInvestment;
  final double? totalLiabilities;
  final double? totalMonthlyPremium;
}

class DashboardDistributionSegment {
  const DashboardDistributionSegment({
    required this.label,
    required this.value,
    required this.colorValue,
  });

  final String label;
  final double value;
  final int colorValue;
}

class DashboardDistributionCardData {
  const DashboardDistributionCardData({
    required this.cardTitle,
    required this.chartTitle,
    required this.totalValue,
    required this.totalValueColorValue,
    required this.chartBackgroundColorValue,
    required this.iconCodePoint,
    required this.segments,
  });

  final String cardTitle;
  final String chartTitle;
  final double totalValue;
  final int totalValueColorValue;
  final int chartBackgroundColorValue;
  final int iconCodePoint;
  final List<DashboardDistributionSegment> segments;

  bool get hasData => segments.any((segment) => segment.value > 0);
}

class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.avatarColorValue,
  });

  final String displayName;
  final String email;
  final String phoneNumber;
  final int avatarColorValue;

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '';
    return name[0].toUpperCase();
  }
}

class DashboardAdvisorInfo {
  const DashboardAdvisorInfo({
    required this.isAvailable,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.avatarColorValue,
  });

  final bool isAvailable;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final int avatarColorValue;

  String get initials {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) {
      return '?';
    }
    return name[0].toUpperCase();
  }
}

class DashboardInsightsData {
  const DashboardInsightsData({
    required this.distributionCards,
    required this.advisorInfo,
  });

  final List<DashboardDistributionCardData> distributionCards;
  final DashboardAdvisorInfo advisorInfo;
}
