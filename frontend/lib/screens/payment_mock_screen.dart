import 'package:flutter/material.dart';

import '../app_localization.dart';
import '../models.dart';

class PaymentMockScreen extends StatefulWidget {
  const PaymentMockScreen({
    super.key,
    required this.activity,
    required this.localization,
  });

  final ActivityItem activity;
  final AppLocalization localization;

  @override
  State<PaymentMockScreen> createState() => _PaymentMockScreenState();
}

class _PaymentMockScreenState extends State<PaymentMockScreen> {
  int _selectedMethod = 0;
  bool _submitting = false;

  Future<void> _confirmPay() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalization i18n = widget.localization;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.tr('payTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.activity.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.tr('paySubtitle'),
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '契约金: ¥${widget.activity.contractAmount}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            icon: Icons.account_balance_wallet_outlined,
            title: '支付宝 Alipay',
            selected: _selectedMethod == 0,
            onTap: () => setState(() => _selectedMethod = 0),
          ),
          _PaymentMethodTile(
            icon: Icons.chat_outlined,
            title: '微信支付 WeChat Pay',
            selected: _selectedMethod == 1,
            onTap: () => setState(() => _selectedMethod = 1),
          ),
          _PaymentMethodTile(
            icon: Icons.credit_card_outlined,
            title: '银行卡 Bank Card',
            selected: _selectedMethod == 2,
            onTap: () => setState(() => _selectedMethod = 2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _confirmPay,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _submitting ? '${i18n.tr('payNow')}...' : i18n.tr('payNow'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Color(0xFF22C55E))
            : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
