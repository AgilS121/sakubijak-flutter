import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Tambahkan method ini di SharedPrefHelper
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    return userData != null ? jsonDecode(userData) : null;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', pin);
  }

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_pin');
  }

  static Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pin');
  }

  // PIN Setup Status
  static Future<void> setPinSetup(bool isSetup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_setup', isSetup);
  }

  static Future<bool> isPinSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('pin_setup') ?? false;
  }

  // User Role Management
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // First Login Status
  static Future<void> setFirstLogin(bool isFirstLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_login', isFirstLogin);
  }

  static Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_login') ?? true;
  }

  // Clear all data on logout
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  // Add this method to get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  // Add this method to clear user email (useful for logout)
  static Future<void> clearUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
  }
}
