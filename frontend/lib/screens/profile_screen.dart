import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../app_localization.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import '../widgets/avatar_badge.dart';
import 'activity_bucket_screen.dart';
import 'personal_info_screen.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.sessionController,
    required this.localization,
    this.embedded = false,
  });

  final SessionController sessionController;
  final AppLocalization localization;
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  int _createdCount = 0;
  int _joinedCount = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final UserSession? session = widget.sessionController.session;
    if (session == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    try {
      final List<ActivityItem> created =
          await ApiService.instance.getActivitiesByCreator(session.userId);
      final List<ActivityItem> joined =
          await ApiService.instance.getActivitiesByParticipant(session.userId);
      final UserProfile profile = await ApiService.instance.getUserProfile(
        userId: session.userId,
      );
      if (!mounted) return;
      setState(() {
        _createdCount = created.length;
        _joinedCount = joined.length;
        _profile = profile;
        _loading = false;
      });
      await _resolveCityFromLocation();
    } on ApiException catch (error) {
      _showMessage(error.message);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resolveCityFromLocation() async {
    final UserProfile? profile = _profile;
    final UserSession? session = widget.sessionController.session;
    if (profile == null || session == null) return;
    try {
      final bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty || !mounted) return;
      final Placemark p = placemarks.first;
      final String nextCity =
          (p.locality?.isNotEmpty == true ? p.locality : p.administrativeArea) ??
              (profile.city ?? '');
      if (nextCity.isEmpty || nextCity == profile.city) return;
      final UserProfile updated = await ApiService.instance.updateUserProfile(
        userId: session.userId,
        displayName: _displayName,
        gender: _gender,
        bio: _bio,
        city: nextCity,
        address: _address,
        avatar: _avatarId,
      );
      if (!mounted) return;
      setState(() => _profile = updated);
    } catch (_) {
      // Keep silent to avoid interrupting the profile flow.
    }
  }

  String get _displayName {
    final UserSession? session = widget.sessionController.session;
    final UserProfile? profile = _profile;
    if (profile?.displayName?.trim().isNotEmpty == true) {
      return profile!.displayName!.trim();
    }
    return session?.username ?? '趣同行';
  }

  String get _gender {
    final String? value = _profile?.gender?.trim();
    return value == null || value.isEmpty ? '保密' : value;
  }

  String get _bio {
    final String? value = _profile?.bio?.trim();
    return value == null || value.isEmpty ? '热爱同城局，欢迎来一起发车。' : value;
  }

  String get _city {
    final String? value = _profile?.city?.trim();
    return value == null || value.isEmpty ? '等待定位' : value;
  }

  String get _address {
    final String? value = _profile?.address?.trim();
    return value == null || value.isEmpty ? '暂未填写详细地址' : value;
  }

  String? get _avatarId => _profile?.avatar;

  Future<void> _openEditProfile() async {
    final UserSession? session = widget.sessionController.session;
    final UserProfile? profile = _profile;
    if (session == null || profile == null) return;
    final ProfileEditResult? result = await Navigator.push<ProfileEditResult>(
      context,
      MaterialPageRoute<ProfileEditResult>(
        builder: (_) => ProfileEditScreen(
          userId: session.userId,
          username: session.username,
          initialProfile: profile,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _profile = result.profile);
    _showMessage('资料已更新');
  }

  Future<void> _logout() async {
    await ApiService.instance.logout();
    await widget.sessionController.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalization i18n = widget.localization;
    final UserSession? session = widget.sessionController.session;
    if (_loading) {
      return widget.embedded
          ? const Center(child: CircularProgressIndicator())
          : const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session == null) {
      final Widget body = Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('去登录'),
        ),
      );
      if (widget.embedded) return body;
      return Scaffold(
        appBar: AppBar(title: Text(i18n.tr('profile'))),
        body: body,
      );
    }

    final Widget profileBody = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF3F5FF), Color(0xFFF9FBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x336A5AE0),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AvatarBadge(
                        name: _displayName,
                        avatarId: _avatarId,
                        radius: 34,
                        showRing: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _ProfileChip(label: _gender),
                                _ProfileChip(label: _city),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _bio,
                    style: const TextStyle(
                      color: Color(0xFFF5F3FF),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _GlassInfoCard(
                          title: '邮箱',
                          value: session.email ?? i18n.tr('notFilled'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassInfoCard(
                          title: '手机',
                          value: session.phone ?? i18n.tr('notFilled'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ActivityBucketScreen(
                              sessionController: widget.sessionController,
                              bucketType: ActivityBucketType.created,
                            ),
                          ),
                        );
                      },
                      child: _StatCard(
                        title: '我发起的活动',
                        value: _createdCount.toString(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ActivityBucketScreen(
                              sessionController: widget.sessionController,
                              bucketType: ActivityBucketType.joined,
                            ),
                          ),
                        );
                      },
                      child: _StatCard(
                        title: '我参与的活动',
                        value: _joinedCount.toString(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '个人空间',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              icon: Icons.edit_note_rounded,
              title: '编辑资料',
              subtitle: '修改头像、昵称、地址和个人简介',
              onTap: _openEditProfile,
            ),
            _ProfileMenuTile(
              icon: Icons.perm_identity_rounded,
              title: i18n.tr('personalInfo'),
              subtitle: '查看当前资料详情',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PersonalInfoScreen(
                    displayName: _displayName,
                    gender: _gender,
                    city: _city,
                    address: _address,
                    bio: _bio,
                    avatarId: _avatarId,
                  ),
                ),
              ),
            ),
            _ProfileMenuTile(
              icon: Icons.settings_outlined,
              title: i18n.tr('settings'),
              subtitle: '应用偏好与提醒设置',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
            _ProfileMenuTile(
              icon: Icons.manage_accounts_rounded,
              title: '活动管理台',
              subtitle: '查看审核待办和参与状态',
              onTap: () => Navigator.pushNamed(context, '/manage'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('退出账号'),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) return profileBody;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.tr('profile'))),
      body: profileBody,
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlassInfoCard extends StatelessWidget {
  const _GlassInfoCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1EFFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(color: Color(0xFFE9E7FF), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
