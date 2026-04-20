import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const <Widget>[
          _SectionTitle(title: '账号与安全'),
          _SettingTile(
            icon: Icons.lock_outline,
            title: '登录与安全',
            subtitle: '修改密码、设备管理、异地登录提醒',
          ),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            title: '隐私设置',
            subtitle: '谁可以看到我、黑名单与屏蔽管理',
          ),
          _SectionTitle(title: '偏好设置'),
          _SettingTile(
            icon: Icons.notifications_none,
            title: '消息通知',
            subtitle: '通知提醒、声音与震动开关',
          ),
          _SettingTile(
            icon: Icons.palette_outlined,
            title: '外观设置',
            subtitle: '字体大小、主题模式、显示密度',
          ),
          _SectionTitle(title: '通用'),
          _SettingTile(
            icon: Icons.help_outline,
            title: '帮助与反馈',
            subtitle: '常见问题、意见反馈、联系客服',
          ),
          _SettingTile(
            icon: Icons.info_outline,
            title: '关于趣同行',
            subtitle: '版本信息、用户协议、隐私政策',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6D5EF9)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
