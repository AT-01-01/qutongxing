import 'package:flutter/foundation.dart';

enum AppLanguage { zhHans, zhHant, ja, en }

class AppLocalization extends ChangeNotifier {
  AppLanguage _language = AppLanguage.zhHans;

  AppLanguage get language => _language;

  String get languageLabel {
    switch (_language) {
      case AppLanguage.zhHans:
        return '简体中文';
      case AppLanguage.zhHant:
        return '繁體中文';
      case AppLanguage.ja:
        return '日本語';
      case AppLanguage.en:
        return 'English';
    }
  }

  List<AppLanguage> get supportedLanguages => AppLanguage.values;

  String languageDisplay(AppLanguage language) {
    switch (language) {
      case AppLanguage.zhHans:
        return '简体中文';
      case AppLanguage.zhHant:
        return '繁體中文';
      case AppLanguage.ja:
        return '日本語';
      case AppLanguage.en:
        return 'English';
    }
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }

  String tr(String key) {
    final Map<String, String>? localized = _localizedValues[_language];
    return localized?[key] ??
        _localizedValues[AppLanguage.zhHans]?[key] ??
        key;
  }
}

const Map<AppLanguage, Map<String, String>> _localizedValues =
    <AppLanguage, Map<String, String>>{
      AppLanguage.zhHans: <String, String>{
        'appName': '趣同行',
        'login': '登录',
        'loginProcessing': '登录中...',
        'welcomeBack': '欢迎回来，请登录你的账号',
        'usernameOrPhone': '用户名或手机号',
        'password': '密码',
        'noAccountGoRegister': '没有账号？去注册',
        'otherLoginMethods': '其他登录方式',
        'wechat': '微信',
        'qq': 'QQ',
        'phone': '手机号',
        'phoneLogin': '手机号登录',
        'phoneNumber': '手机号',
        'verificationCode': '验证码',
        'cancel': '取消',
        'confirmLogin': '登录',
        'agreementPrefix': '我已阅读并同意',
        'userAgreement': '《用户协议》',
        'and': '和',
        'legalDocs': '《法律备书》',
        'agreementRequired': '请先同意用户协议和法律备书',
        'sdkHint':
            '注：QQ/微信/手机号入口支持调试流程，Web 调试可先使用模拟登录页。',
        'register': '注册',
        'registerProcessing': '注册中...',
        'createAccount': '创建账号',
        'joinSlogan': '加入趣同行，和伙伴一起出发',
        'username': '用户名',
        'email': '邮箱',
        'submitRegister': '立即注册',
        'region': '地区 / 语言',
        'languageSwitched': '页面语言已切换为',
        'activities': '活动列表',
        'joinNow': '立即报名',
        'applyQuit': '申请退出',
        'cancelApplication': '取消申请',
        'deleteRecord': '删除记录',
        'selfJoinBlocked': '不能报名自己创建的活动',
        'confirmJoinTitle': '确认报名',
        'confirmJoinContent': '是否确认报名该活动？下一步将进入支付确认页面。',
        'goToPay': '去支付',
        'payTitle': '支付确认',
        'paySubtitle': '模拟支付页面（Web 调试）',
        'payNow': '确认支付',
        'paySuccess': '支付成功，已提交报名申请',
        'payCancelled': '你已取消支付',
        'profile': '个人中心',
        'settings': '设置',
        'personalInfo': '个人信息',
        'privacy': '个人隐私',
        'notification': '消息通知',
        'security': '账号安全',
        'helpCenter': '帮助中心',
        'logout': '退出登录',
        'myDashboard': '我的主页',
        'createdActivities': '创建活动',
        'joinedActivities': '参加活动',
        'notFilled': '未填写',
        'navigateTo': '进入',
      },
      AppLanguage.zhHant: <String, String>{
        'appName': '趣同行',
        'login': '登入',
        'loginProcessing': '登入中...',
        'welcomeBack': '歡迎回來，請登入你的帳號',
        'usernameOrPhone': '用戶名或手機號',
        'password': '密碼',
        'noAccountGoRegister': '沒有帳號？去註冊',
        'otherLoginMethods': '其他登入方式',
        'wechat': '微信',
        'qq': 'QQ',
        'phone': '手機號',
        'phoneLogin': '手機號登入',
        'phoneNumber': '手機號',
        'verificationCode': '驗證碼',
        'cancel': '取消',
        'confirmLogin': '登入',
        'agreementPrefix': '我已閱讀並同意',
        'userAgreement': '《用戶協議》',
        'and': '和',
        'legalDocs': '《法律備書》',
        'agreementRequired': '請先同意用戶協議和法律備書',
        'sdkHint':
            '註：QQ/微信/手機號入口支援調試流程，Web 調試可先使用模擬登入頁。',
        'register': '註冊',
        'registerProcessing': '註冊中...',
        'createAccount': '建立帳號',
        'joinSlogan': '加入趣同行，和夥伴一起出發',
        'username': '用戶名',
        'email': '郵箱',
        'submitRegister': '立即註冊',
        'region': '地區 / 語言',
        'languageSwitched': '頁面語言已切換為',
        'activities': '活動列表',
        'joinNow': '立即報名',
        'applyQuit': '申請退出',
        'cancelApplication': '取消申請',
        'deleteRecord': '刪除記錄',
        'selfJoinBlocked': '不能報名自己建立的活動',
        'confirmJoinTitle': '確認報名',
        'confirmJoinContent': '是否確認報名該活動？下一步將進入支付確認頁面。',
        'goToPay': '去支付',
        'payTitle': '支付確認',
        'paySubtitle': '模擬支付頁面（Web 調試）',
        'payNow': '確認支付',
        'paySuccess': '支付成功，已提交報名申請',
        'payCancelled': '你已取消支付',
        'profile': '個人中心',
        'settings': '設置',
        'personalInfo': '個人信息',
        'privacy': '個人隱私',
        'notification': '消息通知',
        'security': '帳號安全',
        'helpCenter': '幫助中心',
        'logout': '退出登入',
        'myDashboard': '我的主頁',
        'createdActivities': '建立活動',
        'joinedActivities': '參加活動',
        'notFilled': '未填寫',
        'navigateTo': '進入',
      },
      AppLanguage.ja: <String, String>{
        'appName': '趣同行',
        'login': 'ログイン',
        'loginProcessing': 'ログイン中...',
        'welcomeBack': 'おかえりなさい。アカウントでログインしてください。',
        'usernameOrPhone': 'ユーザー名または電話番号',
        'password': 'パスワード',
        'noAccountGoRegister': 'アカウントがないですか？登録へ',
        'otherLoginMethods': 'その他のログイン方法',
        'wechat': 'WeChat',
        'qq': 'QQ',
        'phone': '電話番号',
        'phoneLogin': '電話番号ログイン',
        'phoneNumber': '電話番号',
        'verificationCode': '認証コード',
        'cancel': 'キャンセル',
        'confirmLogin': 'ログイン',
        'agreementPrefix': '私は',
        'userAgreement': '「利用規約」',
        'and': 'と',
        'legalDocs': '「法的文書」',
        'agreementRequired': '利用規約と法的文書への同意が必要です',
        'sdkHint':
            '注: QQ/WeChat/電話番号はモック導線対応です。Web デバッグでは仮ページで利用できます。SDK ready for future integration.',
        'register': '登録',
        'registerProcessing': '登録中...',
        'createAccount': 'アカウント作成',
        'joinSlogan': '趣同行で仲間と一緒に出発しよう',
        'username': 'ユーザー名',
        'email': 'メール',
        'submitRegister': '今すぐ登録',
        'region': '地域 / 言語',
        'languageSwitched': '表示言語を切り替えました:',
        'activities': 'アクティビティ一覧',
        'joinNow': '今すぐ参加',
        'applyQuit': '退出申請',
        'cancelApplication': '申請取り消し',
        'deleteRecord': '記録削除',
        'selfJoinBlocked': '自分が作成した活動には参加できません',
        'confirmJoinTitle': '参加確認',
        'confirmJoinContent': 'この活動に参加しますか？次に支払い確認ページへ移動します。',
        'goToPay': '支払いへ',
        'payTitle': '支払い確認',
        'paySubtitle': 'モック支払いページ（Web デバッグ）',
        'payNow': '支払いを確定',
        'paySuccess': '支払い完了、参加申請を送信しました',
        'payCancelled': '支払いをキャンセルしました',
        'profile': 'マイページ',
        'settings': '設定',
        'personalInfo': '個人情報',
        'privacy': 'プライバシー',
        'notification': '通知',
        'security': 'アカウントセキュリティ',
        'helpCenter': 'ヘルプセンター',
        'logout': 'ログアウト',
        'myDashboard': 'ダッシュボード',
        'createdActivities': '作成した活動',
        'joinedActivities': '参加した活動',
        'notFilled': '未入力',
        'navigateTo': '移動',
      },
      AppLanguage.en: <String, String>{
        'appName': 'Qutongxing',
        'login': 'Login',
        'loginProcessing': 'Signing in...',
        'welcomeBack': 'Welcome back. Please sign in to continue.',
        'usernameOrPhone': 'Username or phone',
        'password': 'Password',
        'noAccountGoRegister': 'No account? Register now',
        'otherLoginMethods': 'Other sign-in methods',
        'wechat': 'WeChat',
        'qq': 'QQ',
        'phone': 'Phone',
        'phoneLogin': 'Phone login',
        'phoneNumber': 'Phone number',
        'verificationCode': 'Verification code',
        'cancel': 'Cancel',
        'confirmLogin': 'Login',
        'agreementPrefix': 'I have read and agree to',
        'userAgreement': 'User Agreement',
        'and': 'and',
        'legalDocs': 'Legal Documents',
        'agreementRequired': 'Please agree to the user agreement first',
        'sdkHint':
            'Note: QQ/WeChat/Phone are connected with a mock flow for web debug. SDK ready for future integration.',
        'register': 'Register',
        'registerProcessing': 'Registering...',
        'createAccount': 'Create account',
        'joinSlogan': 'Join Qutongxing and start with your friends',
        'username': 'Username',
        'email': 'Email',
        'submitRegister': 'Create account',
        'region': 'Region / Language',
        'languageSwitched': 'Language switched to',
        'activities': 'Activities',
        'joinNow': 'Join now',
        'applyQuit': 'Request quit',
        'cancelApplication': 'Cancel request',
        'deleteRecord': 'Delete record',
        'selfJoinBlocked': 'You cannot join your own activity',
        'confirmJoinTitle': 'Confirm join',
        'confirmJoinContent':
            'Confirm joining this activity? Next, you will enter a mock payment page.',
        'goToPay': 'Go to payment',
        'payTitle': 'Payment confirmation',
        'paySubtitle': 'Mock payment page for web debug',
        'payNow': 'Pay now',
        'paySuccess': 'Payment successful. Application submitted.',
        'payCancelled': 'Payment cancelled.',
        'profile': 'Profile',
        'settings': 'Settings',
        'personalInfo': 'Personal info',
        'privacy': 'Privacy',
        'notification': 'Notifications',
        'security': 'Security',
        'helpCenter': 'Help center',
        'logout': 'Log out',
        'myDashboard': 'Dashboard',
        'createdActivities': 'Created',
        'joinedActivities': 'Joined',
        'notFilled': 'Not provided',
        'navigateTo': 'Open',
      },
    };
