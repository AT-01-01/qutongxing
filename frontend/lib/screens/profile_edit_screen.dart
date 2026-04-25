import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../widgets/avatar_badge.dart';

class ProfileEditResult {
  const ProfileEditResult({required this.profile});

  final UserProfile profile;
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.initialProfile,
  });

  final int userId;
  final String username;
  final UserProfile initialProfile;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _addressController;
  late String _gender;
  late String _city;
  String? _avatarId;
  late bool _realNameVerified;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.initialProfile.displayName?.trim().isNotEmpty == true
          ? widget.initialProfile.displayName
          : widget.username,
    );
    _bioController = TextEditingController(text: widget.initialProfile.bio ?? '');
    _addressController = TextEditingController(
      text: widget.initialProfile.address ?? '',
    );
    _gender = (widget.initialProfile.gender?.isNotEmpty ?? false)
        ? widget.initialProfile.gender!
        : '男';
    _city = widget.initialProfile.city ?? '未设置';
    _avatarId = widget.initialProfile.avatar;
    _realNameVerified = widget.initialProfile.realNameVerified;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final UserProfile profile = await ApiService.instance.updateUserProfile(
        userId: widget.userId,
        displayName: _displayNameController.text.trim().isEmpty
            ? widget.username
            : _displayNameController.text.trim(),
        gender: _gender,
        bio: _bioController.text.trim(),
        city: _city,
        address: _addressController.text.trim(),
        realNameVerified: _realNameVerified,
        avatar: _avatarId,
      );
      if (!mounted) return;
      Navigator.pop(context, ProfileEditResult(profile: profile));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0x18FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          '编辑资料',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving ? '保存中' : '保存',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 26),
                      children: <Widget>[
                        const Text(
                          '头像风格',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: AvatarBadge(
                            name: _displayNameController.text,
                            avatarId: _avatarId,
                            radius: 42,
                            showRing: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            ...kAvatarPresets.map((AvatarPreset preset) {
                              final bool selected = _avatarId == preset.id;
                              return InkWell(
                                onTap: () => setState(() => _avatarId = preset.id),
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFEDE9FE)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF6A5AE0)
                                          : const Color(0xFFE3E8F5),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      AvatarBadge(
                                        name: widget.username,
                                        avatarId: preset.id,
                                        radius: 20,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        preset.label,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            InkWell(
                              onTap: () => setState(() => _avatarId = null),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _avatarId == null
                                      ? const Color(0xFFE0F2FE)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _avatarId == null
                                        ? const Color(0xFF22A3F6)
                                        : const Color(0xFFE3E8F5),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Color(0xFF6A5AE0),
                                      child: Text(
                                        'Q',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '首字母',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _EditCard(
                          child: Column(
                            children: <Widget>[
                              TextField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: '展示名称',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _gender,
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem<String>(
                                    value: '男',
                                    child: Text('男'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '女',
                                    child: Text('女'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '保密',
                                    child: Text('保密'),
                                  ),
                                ],
                                onChanged: _realNameVerified
                                    ? null
                                    : (String? value) {
                                  if (value != null) {
                                    setState(() => _gender = value);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: '性别',
                                  prefixIcon: Icon(Icons.wc_rounded),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _realNameVerified,
                                onChanged: (bool value) {
                                  setState(() => _realNameVerified = value);
                                },
                                title: const Text('实名认证状态'),
                                subtitle: Text(
                                  _realNameVerified
                                      ? '已实名，性别已按实名信息锁定'
                                      : '未实名，性别可手动选择',
                                ),
                                secondary: Icon(
                                  _realNameVerified
                                      ? Icons.verified_user_rounded
                                      : Icons.gpp_maybe_outlined,
                                  color: const Color(0xFF6A5AE0),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFDDE2FF)),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF6A5AE0),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '当前城市：$_city',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: '详细地址',
                                  prefixIcon: Icon(Icons.explore_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _bioController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: '个人简介',
                                  prefixIcon: Icon(Icons.mode_comment_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: <Color>[Color(0xFF6A5AE0), Color(0xFF9D50BB)],
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x336A5AE0),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: Text(_saving ? '保存中...' : '保存资料'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
