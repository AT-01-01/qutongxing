import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_localization.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.sessionController,
    required this.localization,
  });

  final SessionController sessionController;
  final AppLocalization localization;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _agreed = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveAndEnter(UserSession session) async {
    await widget.sessionController.saveSession(session);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/activities');
  }

  Future<void> _handleLogin() async {
    final AppLocalization i18n = widget.localization;
    if (!_agreed) {
      _showMessage(i18n.tr('agreementRequired'));
      return;
    }
    if (_accountController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('请输入账号和密码');
      return;
    }

    setState(() => _loading = true);
    try {
      final UserSession session = await ApiService.instance.login(
        usernameOrPhone: _accountController.text.trim(),
        password: _passwordController.text,
      );
      await _saveAndEnter(session);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleWechatLogin() async {
    if (!_validateAgreement()) return;
    final Map<String, String>? mockResult = await _showThirdPartyMockDialog(
      providerName: widget.localization.tr('wechat'),
      suggestedId: 'flutter_wechat_demo',
      suggestedName: '微信用户',
    );
    if (mockResult == null) return;

    setState(() => _loading = true);
    try {
      final UserSession session = await ApiService.instance.wechatLogin(
        wechatId: mockResult['id']!,
        username: mockResult['name'],
      );
      await _saveAndEnter(session);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleQqLogin() async {
    if (!_validateAgreement()) return;
    final Map<String, String>? mockResult = await _showThirdPartyMockDialog(
      providerName: widget.localization.tr('qq'),
      suggestedId: 'flutter_qq_demo',
      suggestedName: 'QQ用户',
    );
    if (mockResult == null) return;

    setState(() => _loading = true);
    try {
      final UserSession session = await ApiService.instance.qqLogin(
        qqId: mockResult['id']!,
        username: mockResult['name'],
      );
      await _saveAndEnter(session);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleSmsLogin() async {
    final AppLocalization i18n = widget.localization;
    if (!_validateAgreement()) return;

    final TextEditingController phoneController = TextEditingController(
      text: '13800138000',
    );
    final TextEditingController codeController = TextEditingController(
      text: '123456',
    );
    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(i18n.tr('phoneLogin')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: i18n.tr('phoneNumber')),
              ),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: i18n.tr('verificationCode'),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.tr('confirmLogin')),
            ),
          ],
        );
      },
    );
    if (submit != true) return;

    setState(() => _loading = true);
    try {
      final UserSession session = await ApiService.instance.smsLogin(
        phone: phoneController.text.trim(),
        code: codeController.text.trim(),
      );
      await _saveAndEnter(session);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
      phoneController.dispose();
      codeController.dispose();
    }
  }

  Future<Map<String, String>?> _showThirdPartyMockDialog({
    required String providerName,
    required String suggestedId,
    required String suggestedName,
  }) async {
    final TextEditingController idController = TextEditingController(
      text: suggestedId,
    );
    final TextEditingController nameController = TextEditingController(
      text: suggestedName,
    );
    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$providerName 登录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: idController,
                decoration: InputDecoration(
                  labelText: '$providerName 账号ID',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '昵称',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.localization.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, <String, String>{
                  'id': idController.text.trim(),
                  'name': nameController.text.trim(),
                });
              },
              child: Text(widget.localization.tr('confirmLogin')),
            ),
          ],
        );
      },
    );
    idController.dispose();
    nameController.dispose();
    return result;
  }

  bool _validateAgreement() {
    if (_agreed) {
      return true;
    }
    _showMessage(widget.localization.tr('agreementRequired'));
    return false;
  }

  void _showLegalSheet() {
    final AppLocalization i18n = widget.localization;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${i18n.tr('userAgreement')} & ${i18n.tr('legalDocs')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '1. 账号仅限本人使用。\n'
                '2. 报名后请按活动规则履约，违约可能影响信用。\n'
                '3. 平台仅提供撮合服务，具体活动风险由参与者自行评估。',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('我已了解'),
                ),
              ),
            ],
          ),
        );
      },
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFEFF3FF), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const SizedBox(height: 16),
              const Text(
                '趣同行',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                i18n.tr('welcomeBack'),
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _accountController,
                        decoration: InputDecoration(
                          labelText: i18n.tr('usernameOrPhone'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: i18n.tr('password'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            _loading
                                ? i18n.tr('loginProcessing')
                                : i18n.tr('login'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Checkbox(
                            value: _agreed,
                            onChanged: (bool? value) =>
                                setState(() => _agreed = value ?? false),
                          ),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                Text(i18n.tr('agreementPrefix')),
                                TextButton(
                                  onPressed: _showLegalSheet,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(i18n.tr('userAgreement')),
                                ),
                                Text(i18n.tr('and')),
                                TextButton(
                                  onPressed: _showLegalSheet,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(i18n.tr('legalDocs')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(i18n.tr('noAccountGoRegister')),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                i18n.tr('otherLoginMethods'),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _handleQqLogin,
                      icon: const FaIcon(
                        FontAwesomeIcons.qq,
                        color: Color(0xFF12B7F5),
                        size: 18,
                      ),
                      label: Text(i18n.tr('qq')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _handleWechatLogin,
                      icon: const FaIcon(
                        FontAwesomeIcons.weixin,
                        color: Color(0xFF07C160),
                        size: 18,
                      ),
                      label: Text(i18n.tr('wechat')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _handleSmsLogin,
                      icon: const Icon(Icons.sms_outlined),
                      label: Text(i18n.tr('phone')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                i18n.tr('sdkHint'),
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
