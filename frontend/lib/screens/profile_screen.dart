import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../app_localization.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import 'activity_bucket_screen.dart';
import 'personal_info_screen.dart';
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
  String _gender = '男';
  String _bio = '热爱户外和城市探索，欢迎约局。';
  String _city = '定位中';
  String _address = '西安市雁塔区高新一路';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final UserSession? session = widget.sessionController.session;
    if (session == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final List<ActivityItem> created = await ApiService.instance
          .getActivitiesByCreator(session.userId);
      final List<ActivityItem> joined = await ApiService.instance
          .getActivitiesByParticipant(session.userId);
      final UserProfile profile = await ApiService.instance.getUserProfile(
        userId: session.userId,
      );
      if (!mounted) return;
      setState(() {
        _createdCount = created.length;
        _joinedCount = joined.length;
        _applyProfile(profile, fallbackUsername: session.username);
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

  void _applyProfile(UserProfile profile, {required String fallbackUsername}) {
    _displayName =
        (profile.displayName?.trim().isNotEmpty == true
            ? profile.displayName!.trim()
            : fallbackUsername);
    _gender =
        (profile.gender?.trim().isNotEmpty == true
            ? profile.gender!.trim()
            : _gender);
    _bio =
        (profile.bio?.trim().isNotEmpty == true ? profile.bio!.trim() : _bio);
    _city =
        (profile.city?.trim().isNotEmpty == true ? profile.city!.trim() : _city);
    _address =
        (profile.address?.trim().isNotEmpty == true
            ? profile.address!.trim()
            : _address);
  }

  Future<void> _resolveCityFromLocation() async {
    try {
      final bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() => _city = '定位服务未开启');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _city = '未授予定位权限');
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      if (placemarks.isEmpty) {
        setState(() => _city = '定位成功');
        return;
      }
      final Placemark p = placemarks.first;
      setState(() {
        _city = (p.locality?.isNotEmpty == true
                ? p.locality
                : p.administrativeArea) ??
            '定位成功';
      });
      await _syncProfileSilently();
    } catch (_) {
      if (!mounted) return;
      setState(() => _city = '定位失败');
    }
  }

  Future<void> _syncProfileSilently() async {
    final UserSession? session = widget.sessionController.session;
    if (session == null) return;
    try {
      await ApiService.instance.updateUserProfile(
        userId: session.userId,
        displayName: _displayName,
        gender: _gender,
        bio: _bio,
        city: _city,
        address: _address,
      );
    } catch (_) {
      // 静默失败，避免定位状态影响主流程。
    }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      if (widget.embedded) {
        return body;
      }
      return Scaffold(
        appBar: AppBar(title: Text(i18n.tr('profile'))),
        body: body,
      );
    }
    final Widget profileBody = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: <Widget>[
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  labelStyle: const TextStyle(fontSize: 11),
                                  label: Text('性别：$_gender'),
                                ),
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  labelStyle: const TextStyle(fontSize: 11),
                                  label: Text('所在地：$_city'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF6D5EF9),
                        child: Text(
                          _displayName.isEmpty ? '趣' : _displayName.characters.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('邮箱：${session.email ?? i18n.tr('notFilled')}'),
                  Text(
                    '${i18n.tr('phoneNumber')}: ${session.phone ?? i18n.tr('notFilled')}',
                  ),
                  const SizedBox(height: 6),
                  Text('地址：$_address'),
                  const SizedBox(height: 8),
                  Text(
                    '个人描述：$_bio',
                    style: const TextStyle(color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showProfileEditSheet(session.userId),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('编辑资料'),
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                            title: '${i18n.tr('createdActivities')}（可查看）',
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
                            title: '${i18n.tr('joinedActivities')}（可查看）',
                            value: _joinedCount.toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            i18n.tr('myDashboard'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _ProfileMenuTile(
            icon: Icons.settings_outlined,
            title: i18n.tr('settings'),
            subtitle: '应用偏好设置',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.badge_outlined,
            title: i18n.tr('personalInfo'),
            subtitle: '查看和更新个人资料',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PersonalInfoScreen(
                  displayName: _displayName,
                  gender: _gender,
                  city: _city,
                  address: _address,
                  bio: _bio,
                ),
              ),
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: i18n.tr('privacy'),
            subtitle: '隐私范围与权限控制',
            onTap: () => _showMessage('${i18n.tr('navigateTo')}${i18n.tr('privacy')}'),
          ),
          _ProfileMenuTile(
            icon: Icons.notifications_outlined,
            title: i18n.tr('notification'),
            subtitle: '消息提醒与免打扰时段',
            onTap: () =>
                _showMessage('${i18n.tr('navigateTo')}${i18n.tr('notification')}'),
          ),
          _ProfileMenuTile(
            icon: Icons.security_outlined,
            title: i18n.tr('security'),
            subtitle: '密码与账号安全管理',
            onTap: () => _showMessage('${i18n.tr('navigateTo')}${i18n.tr('security')}'),
          ),
          _ProfileMenuTile(
            icon: Icons.help_outline,
            title: i18n.tr('helpCenter'),
            subtitle: '常见问题与意见反馈',
            onTap: () =>
                _showMessage('${i18n.tr('navigateTo')}${i18n.tr('helpCenter')}'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/manage'),
            icon: const Icon(Icons.manage_accounts),
            label: const Text('进入活动管理'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('退出账户'),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return profileBody;
    }
    return Scaffold(
      appBar: AppBar(title: Text(i18n.tr('profile'))),
      body: profileBody,
    );
  }

  Future<void> _showProfileEditSheet(int userId) async {
    final TextEditingController displayNameController = TextEditingController(
      text: _displayName,
    );
    final TextEditingController bioController = TextEditingController(text: _bio);
    final TextEditingController addressController = TextEditingController(
      text: _address,
    );
    String selectedGender = _gender == '女' ? '女' : '男';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(labelText: '展示昵称'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: '男', child: Text('男')),
                      DropdownMenuItem<String>(value: '女', child: Text('女')),
                    ],
                    onChanged: (String? value) {
                      if (value == null) return;
                      setSheetState(() {
                        selectedGender = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: '性别'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Text('所在地：$_city（系统定位自动获取）'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: '详细地址'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bioController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '个人描述'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final String nextDisplayName =
                            displayNameController.text.trim().isEmpty
                            ? _displayName
                            : displayNameController.text.trim();
                        final String nextAddress =
                            addressController.text.trim().isEmpty
                            ? _address
                            : addressController.text.trim();
                        final String nextBio = bioController.text.trim().isEmpty
                            ? _bio
                            : bioController.text.trim();
                        try {
                          final UserProfile updated =
                              await ApiService.instance.updateUserProfile(
                                userId: userId,
                                displayName: nextDisplayName,
                                gender: selectedGender,
                                bio: nextBio,
                                city: _city,
                                address: nextAddress,
                              );
                          if (!mounted) return;
                          setState(() {
                            _applyProfile(
                              updated,
                              fallbackUsername:
                                  widget.sessionController.session?.username ??
                                  _displayName,
                            );
                          });
                          Navigator.pop(context);
                          _showMessage('资料已更新');
                        } on ApiException catch (error) {
                          if (!mounted) return;
                          _showMessage(error.message);
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    displayNameController.dispose();
    bioController.dispose();
    addressController.dispose();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
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
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF6D5EF9)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
