import 'package:flutter/material.dart';

class MembershipDisplayInfo {
  final String code;
  final String label;
  final String description;
  final IconData icon;

  const MembershipDisplayInfo({
    required this.code,
    required this.label,
    required this.description,
    required this.icon,
  });

  bool get isGuest => code == 'guest';
}

MembershipDisplayInfo membershipDisplayInfoForTier(String? rawTier) {
  final tier = _normalizeTier(rawTier);
  switch (tier) {
    case 'guest':
      return const MembershipDisplayInfo(
        code: 'guest',
        label: 'Khách trải nghiệm',
        description: 'Bạn đang dùng các tính năng cơ bản trước khi đăng nhập.',
        icon: Icons.explore_rounded,
      );
    case 'plus':
      return const MembershipDisplayInfo(
        code: 'plus',
        label: 'Gói Plus',
        description: 'Tài khoản Plus đang sẵn sàng cho các quyền nâng cao.',
        icon: Icons.workspace_premium_rounded,
      );
    case 'family_plus':
      return const MembershipDisplayInfo(
        code: 'family_plus',
        label: 'Gói FamilyPlus',
        description: 'Tài khoản FamilyPlus dành cho chăm sóc gia đình.',
        icon: Icons.family_restroom_rounded,
      );
    case 'free':
      return const MembershipDisplayInfo(
        code: 'free',
        label: 'Gói Free',
        description: 'Bạn đang dùng gói miễn phí sau khi đăng nhập.',
        icon: Icons.verified_user_rounded,
      );
    default:
      return MembershipDisplayInfo(
        code: tier,
        label: 'Gói ${_titleCase(tier)}',
        description: 'Nami đã ghi nhận trạng thái gói của bạn.',
        icon: Icons.verified_rounded,
      );
  }
}

String _normalizeTier(String? rawTier) {
  final tier = rawTier?.trim().toLowerCase().replaceAll('-', '_') ?? '';
  if (tier.isEmpty) return 'free';
  if (tier == 'familyplus') return 'family_plus';
  if (tier == 'basic') return 'free';
  return tier;
}

String _titleCase(String value) {
  final text = value.replaceAll('_', ' ').trim();
  if (text.isEmpty) return 'Free';
  return text
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
