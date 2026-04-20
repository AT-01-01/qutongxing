import 'package:flutter/foundation.dart';

import 'models.dart';
import 'services/storage_service.dart';

class SessionController extends ChangeNotifier {
  UserSession? _session;
  bool _loading = true;

  UserSession? get session => _session;
  bool get isLoading => _loading;
  bool get isLoggedIn => _session != null;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    _session = await StorageService.readSession();
    _loading = false;
    notifyListeners();
  }

  Future<void> saveSession(UserSession session) async {
    _session = session;
    await StorageService.saveSession(session);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _session = null;
    await StorageService.clearSession();
    notifyListeners();
  }
}
