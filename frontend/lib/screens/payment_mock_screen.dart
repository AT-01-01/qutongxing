import 'package:flutter/material.dart';

import '../models.dart';

class PaymentMockScreen extends StatefulWidget {
  const PaymentMockScreen({
    super.key,
    required this.activity,
  });

  final ActivityItem activity;

  @override
  State<PaymentMockScreen> createState() => _PaymentMockScreenState();
}

class _PaymentMockScreenState extends State<PaymentMockScreen> {
  int _selectedWallet = 0;
  bool _submitting = false;

  Future<void> _confirmConsume() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final List<_PointWallet> wallets = <_PointWallet>[
      const _PointWallet(
        icon: Icons.local_fire_department_outlined,
        title: '活跃积分',
        subtitle: '优先消耗最近获得的活跃积分',
      ),
      const _PointWallet(
        icon: Icons.workspace_premium_outlined,
        title: '组局奖励积分',
        subtitle: '使用历史参与与发起活动获得的奖励积分',
      ),
      const _PointWallet(
        icon: Icons.bolt_outlined,
        title: '签到积分',
        subtitle: '保留高价值积分，优先用签到积分抵扣',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('积分确认')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF4F6FF), Color(0xFFF9FBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.activity.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '本次报名将消耗活动积分，完成确认后会进入待审核状态。',
                    style: TextStyle(
                      color: Color(0xFFF0EDFF),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x20FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '需消耗 ${widget.activity.contractAmount} 积分',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '选择积分来源',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...List<Widget>.generate(wallets.length, (int index) {
              final _PointWallet wallet = wallets[index];
              final bool selected = _selectedWallet == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF6A5AE0)
                        : const Color(0xFFE6EAF5),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () => setState(() => _selectedWallet = index),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFFFD976), Color(0xFFFFA86B)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(wallet.icon, color: const Color(0xFF4B2E18)),
                  ),
                  title: Text(
                    wallet.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(wallet.subtitle),
                  trailing: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? const Color(0xFF6A5AE0)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _confirmConsume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.stars_rounded),
                  label: Text(_submitting ? '确认中...' : '确认消耗积分'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointWallet {
  const _PointWallet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
