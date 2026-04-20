import 'package:flutter/material.dart';

import '../app_localization.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.localization,
    required this.onLanguageSelected,
  });

  final AppLocalization localization;
  final ValueChanged<AppLanguage> onLanguageSelected;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  late AppLanguage _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.localization.language;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final AppLocalization i18n = widget.localization;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.instance.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('${i18n.tr('register')}成功，请登录');
      Navigator.pop(context);
    } on ApiException catch (error) {
      // 优先展示后端返回的字段级校验信息，避免只看到笼统的“参数验证失败”。
      String message = error.message;
      final Map<String, dynamic>? details = error.details;
      if (details != null && details.isNotEmpty) {
        final dynamic fieldErrors = details['fieldErrors'];
        if (fieldErrors is Map && fieldErrors.isNotEmpty) {
          message = '$message：${fieldErrors.values.first}';
        } else {
          final String firstDetail = details.values.first.toString();
          message = '$message：$firstDetail';
        }
      }
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
            colors: <Color>[Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    i18n.tr('createAccount'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                i18n.tr('joinSlogan'),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        DropdownButtonFormField<AppLanguage>(
                          value: _selectedLanguage,
                          decoration: InputDecoration(
                            labelText: i18n.tr('region'),
                            border: const OutlineInputBorder(),
                          ),
                          items: widget.localization.supportedLanguages
                              .map((AppLanguage language) {
                                return DropdownMenuItem<AppLanguage>(
                                  value: language,
                                  child: Text(
                                    widget.localization.languageDisplay(language),
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (AppLanguage? value) {
                            if (value == null) return;
                            setState(() => _selectedLanguage = value);
                            widget.onLanguageSelected(value);
                            _showMessage(
                              '${i18n.tr('languageSwitched')} '
                              '${widget.localization.languageDisplay(value)}',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: i18n.tr('username'),
                            hintText: '3-50位',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            final String v = (value ?? '').trim();
                            if (v.isEmpty) return '请输入用户名';
                            if (v.length < 3 || v.length > 50) {
                              return '用户名长度需在 3-50 位';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: i18n.tr('email'),
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            final String v = (value ?? '').trim();
                            if (v.isEmpty) return '请输入邮箱';
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(v)) {
                              return '邮箱格式不正确';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: i18n.tr('phoneNumber'),
                            hintText: '至少11位',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            final String v = (value ?? '').trim();
                            if (v.isEmpty) return '请输入手机号';
                            if (v.length < 11) return '手机号长度不足';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: i18n.tr('password'),
                            hintText: '6-100位',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            final String v = value ?? '';
                            if (v.isEmpty) return '请输入密码';
                            if (v.length < 6) return '密码至少 6 位';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(
                              _loading
                                  ? i18n.tr('registerProcessing')
                                  : i18n.tr('submitRegister'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
