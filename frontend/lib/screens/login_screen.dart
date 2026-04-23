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
  static const Color _textSecondary = Color(0xFF888888);
  static const Color _fieldBg = Color(0xFFF5F6FA);
  static const Color _pageTop = Color(0xFF6A5AE0);
  static const Color _pageBottom = Color(0xFF8FD3F4);
  static const Color _buttonStart = Color(0xFF6A5AE0);
  static const Color _buttonEnd = Color(0xFF9D50BB);
  static const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(22));
  static const BorderRadius _fieldRadius = BorderRadius.all(
    Radius.circular(14),
  );
  static const BorderRadius _buttonRadius = BorderRadius.all(
    Radius.circular(30),
  );

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _agreed = false;
  bool _showPassword = false;

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

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF667085)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fieldBg,
      border: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _fieldRadius,
        borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const <Widget>[
        CircleAvatar(
          radius: 34,
          backgroundColor: Color(0x26FFFFFF),
          child: Icon(Icons.groups_2_rounded, size: 34, color: Colors.white),
        ),
        SizedBox(height: 14),
        Text(
          '趣同行',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '找到你的同行搭子',
          style: TextStyle(
            color: Color(0xFFEAEAFF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementRow(AppLocalization i18n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: _agreed,
            activeColor: const Color(0xFF6A5AE0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (bool? value) => setState(() => _agreed = value ?? false),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  i18n.tr('agreementPrefix'),
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
                TextButton(
                  onPressed: _showLegalSheet,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    i18n.tr('userAgreement'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5E56E7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  i18n.tr('and'),
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
                TextButton(
                  onPressed: _showLegalSheet,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    i18n.tr('legalDocs'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5E56E7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget icon,
    required String label,
  }) {
    return Column(
      children: <Widget>[
        InkWell(
          onTap: _loading ? null : onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4E7EC)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: icon),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalization i18n = widget.localization;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[_pageTop, _pageBottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x22FFFFFF),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 420),
                builder: (BuildContext context, double value, Widget? child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 18),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: _cardRadius,
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x24000000),
                            blurRadius: 26,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          TextField(
                            controller: _accountController,
                            decoration: _fieldDecoration(
                              hint: i18n.tr('usernameOrPhone'),
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: _fieldDecoration(
                              hint: i18n.tr('password'),
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                splashRadius: 20,
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAgreementRow(i18n),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: _buttonRadius,
                              gradient: const LinearGradient(
                                colors: <Color>[_buttonStart, _buttonEnd],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x666A5AE0),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: _buttonRadius,
                                onTap: _loading ? null : _handleLogin,
                                child: Center(
                                  child: Text(
                                    _loading
                                        ? i18n.tr('loginProcessing')
                                        : i18n.tr('login'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/register'),
                                child: Text(
                                  '注册账号',
                                  style: TextStyle(
                                    color: const Color(0xFF5E56E7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _showMessage('忘记密码功能开发中'),
                                child: const Text(
                                  '忘记密码',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const <Widget>[
                        Expanded(child: Divider(color: Color(0x80FFFFFF))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '或使用以下方式登录',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0x80FFFFFF))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildSocialButton(
                          onTap: _handleQqLogin,
                          label: 'QQ',
                          icon: const FaIcon(
                            FontAwesomeIcons.qq,
                            color: Color(0xFF12B7F5),
                            size: 20,
                          ),
                        ),
                        _buildSocialButton(
                          onTap: _handleWechatLogin,
                          label: '微信',
                          icon: const FaIcon(
                            FontAwesomeIcons.weixin,
                            color: Color(0xFF07C160),
                            size: 20,
                          ),
                        ),
                        _buildSocialButton(
                          onTap: _handleSmsLogin,
                          label: '手机',
                          icon: const Icon(
                            Icons.phone_iphone_rounded,
                            color: Color(0xFF6A5AE0),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '登录即代表你同意平台相关条款并授权必要服务权限',
                      style: TextStyle(color: Color(0xDDEEF2FF), fontSize: 11.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
