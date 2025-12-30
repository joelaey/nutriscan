import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import '../models/scan_result.dart';

class StorageService {
  static const String _userDataKey = 'user_data';
  static const String _scanHistoryKey = 'scan_history';
  static const String _isFirstLaunchKey = 'is_first_launch';

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // User Data Methods
  Future<void> saveUserData(UserData userData) async {
    await _prefs?.setString(_userDataKey, userData.toJsonString());
  }

  UserData? getUserData() {
    final jsonString = _prefs?.getString(_userDataKey);
    if (jsonString != null) {
      return UserData.fromJsonString(jsonString);
    }
    return null;
  }

  Future<void> clearUserData() async {
    await _prefs?.remove(_userDataKey);
  }

  // Scan History Methods
  Future<void> saveScanResult(ScanResult result) async {
    final history = getScanHistory();
    history.insert(0, result); // Add to beginning
    
    // Keep only last 50 scans
    final limitedHistory = history.take(50).toList();
    
    final jsonList = limitedHistory.map((r) => r.toJson()).toList();
    await _prefs?.setString(_scanHistoryKey, jsonEncode(jsonList));
  }

  List<ScanResult> getScanHistory() {
    final jsonString = _prefs?.getString(_scanHistoryKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ScanResult.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> deleteScanResult(String id) async {
    final history = getScanHistory();
    history.removeWhere((r) => r.id == id);
    
    final jsonList = history.map((r) => r.toJson()).toList();
    await _prefs?.setString(_scanHistoryKey, jsonEncode(jsonList));
  }

  Future<void> clearScanHistory() async {
    await _prefs?.remove(_scanHistoryKey);
  }

  // First Launch Check
  bool isFirstLaunch() {
    return _prefs?.getBool(_isFirstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    await _prefs?.setBool(_isFirstLaunchKey, false);
  }

  // Clear All Data
  Future<void> clearAllData() async {
    await _prefs?.clear();
  }

  // Check if user is logged in (profile is complete)
  bool isUserLoggedIn() {
    final userData = getUserData();
    return userData != null && userData.isProfileComplete;
  }
}
