import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_role.dart';
import '../services/ai_service.dart';

/// 设置状态管理 - 支持每个角色独立头像
class SettingsProvider extends ChangeNotifier {
  String _roleId = 'minister';
  double _dailyBudget = 200;
  bool _budgetEnabled = false;
  String? _apiKey;
  String _providerId = 'deepseek';
  String? _customApiUrl;
  String? _customModel;
  String? _backgroundUrl;
  String? _userAvatarUrl;
  
  // 每个角色的独立头像
  Map<String, String> _roleAvatars = {};
  
  SharedPreferences? _prefs;

  String get roleId => _roleId;
  double get dailyBudget => _dailyBudget;
  bool get budgetEnabled => _budgetEnabled;
  String? get apiKey => _apiKey;
  String get providerId => _providerId;
  String? get customApiUrl => _customApiUrl;
  String? get customModel => _customModel;
  String? get backgroundUrl => _backgroundUrl;
  String? get userAvatarUrl => _userAvatarUrl;
  
  // 获取当前角色的头像
  String? get aiAvatarUrl {
    debugPrint('aiAvatarUrl getter: _roleId=$_roleId, _roleAvatars=$_roleAvatars');
    return _roleAvatars[_roleId];
  }
  
  // 获取指定角色的头像
  String? getRoleAvatar(String roleId) => _roleAvatars[roleId];

  AIRole get currentRole => AIRole.getById(_roleId);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _roleId = _prefs?.getString('role_id') ?? 'minister';
    _dailyBudget = _prefs?.getDouble('daily_budget') ?? 200;
    _budgetEnabled = _prefs?.getBool('budget_enabled') ?? false;
    _apiKey = _prefs?.getString('api_key');
    _providerId = _prefs?.getString('provider_id') ?? 'deepseek';
    _customApiUrl = _prefs?.getString('custom_api_url');
    _customModel = _prefs?.getString('custom_model');
    _backgroundUrl = _prefs?.getString('background_url');
    _userAvatarUrl = _prefs?.getString('user_avatar_url');
    
    // 加载所有角色的头像
    _loadRoleAvatars();
    
    notifyListeners();
  }
  
  void _loadRoleAvatars() {
    final roles = ['minister', 'maid', 'servant', 'taoist', 'boss', 'friend', 
                   'cultivation_lover', 'tsundere', 'mom', 'teacher', 
                   'martial_hero', 'space_captain', 'ancient_lady', 'pet'];
    for (var role in roles) {
      final avatar = _prefs?.getString('avatar_$role');
      if (avatar != null && avatar.isNotEmpty) {
        _roleAvatars[role] = avatar;
        debugPrint('_loadRoleAvatars: loaded avatar for $role: $avatar');
      }
    }
    debugPrint('_loadRoleAvatars complete: $_roleAvatars');
  }

  Future<void> setRole(String roleId) async {
    _roleId = roleId;
    await _prefs?.setString('role_id', roleId);
    notifyListeners();
  }

  Future<void> setDailyBudget(double amount) async {
    _dailyBudget = amount;
    await _prefs?.setDouble('daily_budget', amount);
    notifyListeners();
  }

  Future<void> setBudgetEnabled(bool enabled) async {
    _budgetEnabled = enabled;
    await _prefs?.setBool('budget_enabled', enabled);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    await _prefs?.setString('api_key', key);
    notifyListeners();
  }

  Future<void> setProvider(String providerId) async {
    _providerId = providerId;
    await _prefs?.setString('provider_id', providerId);
    notifyListeners();
  }

  Future<void> setCustomApiUrl(String? url) async {
    _customApiUrl = url;
    if (url != null) {
      await _prefs?.setString('custom_api_url', url);
    } else {
      await _prefs?.remove('custom_api_url');
    }
    notifyListeners();
  }

  Future<void> setCustomModel(String? model) async {
    _customModel = model;
    if (model != null) {
      await _prefs?.setString('custom_model', model);
    } else {
      await _prefs?.remove('custom_model');
    }
    notifyListeners();
  }

  Future<void> setBackgroundUrl(String? url) async {
    _backgroundUrl = url;
    if (url != null) {
      await _prefs?.setString('background_url', url);
    } else {
      await _prefs?.remove('background_url');
    }
    notifyListeners();
  }

  Future<void> setUserAvatarUrl(String? url) async {
    if (url != null && url.isNotEmpty) {
      final saved = await _persistAvatarFile(url, 'user');
      if (saved != null) {
        _userAvatarUrl = saved;
        await _prefs?.setString('user_avatar_url', saved);
      }
    } else {
      _userAvatarUrl = null;
      await _prefs?.remove('user_avatar_url');
    }
    notifyListeners();
  }

  /// 持久化头像文件：把 image_picker 临时目录的文件复制到 app 文档目录
  Future<String?> _persistAvatarFile(String tempPath, String prefix) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory(dir.path + '/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      final ext = tempPath.split('.').last.toLowerCase();
      final safeExt = (ext.length <= 4) ? ext : 'jpg';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final dest = File(avatarDir.path + '/' + prefix + '_' + ts.toString() + '.' + safeExt);
      await File(tempPath).copy(dest.path);
      return dest.path;
    } catch (e) {
      debugPrint('_persistAvatarFile error: ' + e.toString());
      return null;
    }
  }



  // 设置当前角色的头像
  Future<void> setAiAvatarUrl(String? url) async {
    notifyListeners();
  }
  
  // 设置指定角色的头像
  Future<void> setRoleAvatar(String roleId, String? url) async {
    debugPrint('setRoleAvatar called: roleId=$roleId, url=$url');
    if (url != null && url.isNotEmpty) {
      _roleAvatars[roleId] = url;
      await _prefs?.setString('avatar_$roleId', url);
    } else {
      _roleAvatars.remove(roleId);
      await _prefs?.remove('avatar_$roleId');
    }
    notifyListeners();
  }
}
