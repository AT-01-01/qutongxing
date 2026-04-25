import 'package:flutter/material.dart';

class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.icon,
    required this.colors,
    required this.label,
  });

  final String id;
  final IconData icon;
  final List<Color> colors;
  final String label;
}

const List<AvatarPreset> kAvatarPresets = <AvatarPreset>[
  AvatarPreset(
    id: 'spark',
    icon: Icons.auto_awesome_rounded,
    colors: <Color>[Color(0xFF6A5AE0), Color(0xFF9D50BB)],
    label: '灵感',
  ),
  AvatarPreset(
    id: 'sport',
    icon: Icons.sports_basketball_rounded,
    colors: <Color>[Color(0xFFFF8A5B), Color(0xFFFFC46B)],
    label: '运动',
  ),
  AvatarPreset(
    id: 'city',
    icon: Icons.location_city_rounded,
    colors: <Color>[Color(0xFF25C1F1), Color(0xFF4F8CFF)],
    label: '同城',
  ),
  AvatarPreset(
    id: 'camera',
    icon: Icons.camera_alt_rounded,
    colors: <Color>[Color(0xFFFF6B8A), Color(0xFFFF9B85)],
    label: '记录',
  ),
  AvatarPreset(
    id: 'music',
    icon: Icons.graphic_eq_rounded,
    colors: <Color>[Color(0xFF15B79E), Color(0xFF49D17D)],
    label: '气氛',
  ),
  AvatarPreset(
    id: 'night',
    icon: Icons.nightlife_rounded,
    colors: <Color>[Color(0xFF1F2A44), Color(0xFF6145E0)],
    label: '夜色',
  ),
];

AvatarPreset? avatarPresetById(String? id) {
  for (final AvatarPreset preset in kAvatarPresets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return null;
}

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.name,
    this.avatarId,
    this.radius = 26,
    this.showRing = false,
  });

  final String name;
  final String? avatarId;
  final double radius;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final AvatarPreset? preset = avatarPresetById(avatarId);
    final String trimmed = name.trim();
    final String fallbackLetter =
        trimmed.isEmpty ? 'Q' : trimmed.substring(0, 1).toUpperCase();

    final Widget inner = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: preset?.colors ??
              const <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: preset == null
            ? Text(
                fallbackLetter,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Icon(
                preset.icon,
                color: Colors.white,
                size: radius * 0.95,
              ),
      ),
    );

    if (!showRing) {
      return inner;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x26FFFFFF), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: inner,
    );
  }
}
