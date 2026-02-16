import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _keyUsers = 'hh_users_v1'; // json map: name -> {salt, hash}

  Future<bool> hasAnyUser() async {
    final raw = await _storage.read(key: _keyUsers);
    return raw != null && raw.trim().isNotEmpty && raw.trim() != '{}';
  }

  Future<bool> isUserRegistered(String fullName) async {
    final m = await _readUsers();
    return m.containsKey(_norm(fullName));
  }

  Future<void> register(String fullName, String password) async {
    final name = _norm(fullName);
    final m = await _readUsers();
    final salt = _randomSalt();
    final hash = _hash(password, salt);
    m[name] = {'salt': salt, 'hash': hash};
    await _storage.write(key: _keyUsers, value: jsonEncode(m));
    await _storage.write(key: 'hh_last_user', value: name);
  }

  Future<bool> login(String fullName, String password) async {
    final name = _norm(fullName);
    final m = await _readUsers();
    final rec = m[name];
    if (rec == null) return false;
    final salt = (rec['salt'] ?? '') as String;
    final hash = (rec['hash'] ?? '') as String;
    final got = _hash(password, salt);
    if (got == hash) {
      await _storage.write(key: 'hh_last_user', value: name);
      return true;
    }
    return false;
  }

  Future<String?> lastUser() async => _storage.read(key: 'hh_last_user');

  String _hash(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> _readUsers() async {
    final raw = await _storage.read(key: _keyUsers);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final v = jsonDecode(raw);
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return <String, dynamic>{};
  }

  String _norm(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String _randomSalt() {
    // Simple deterministic-free salt without external deps.
    final now = DateTime.now().microsecondsSinceEpoch;
    final bytes = utf8.encode('hh::$now::${now % 997}');
    return sha256.convert(bytes).toString().substring(0, 16);
  }
}
