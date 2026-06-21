import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isSuperAdmin = false;
  String _name = '';
  String _address = '';
  String _mobile = '';
  String _hotelName = '';
  String _roomNumber = '';
  String _email = '';
  String _role = 'user';
  String _managedHotelId = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isSuperAdmin => _isSuperAdmin;
  String get name => _name;
  String get address => _address;
  String get mobile => _mobile;
  String get hotelName => _hotelName;
  String get roomNumber => _roomNumber;
  String get email => _email;
  String get role => _role;
  String get managedHotelId => _managedHotelId;
  bool get isManager => _role == 'manager';

  UserProvider() {
    _loadUserSession();
  }

  // Load session from SharedPreferences
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('user_logged_in') ?? false;
    _isSuperAdmin = prefs.getBool('user_is_super_admin') ?? false;
    if (_isLoggedIn) {
      _name = prefs.getString('user_name') ?? '';
      _address = prefs.getString('user_address') ?? '';
      _mobile = prefs.getString('user_mobile') ?? '';
      _hotelName = prefs.getString('user_hotel_name') ?? '';
      _roomNumber = prefs.getString('user_room_number') ?? '';
      _email = prefs.getString('user_email') ?? '';
      _role = prefs.getString('user_role') ?? 'user';
      _managedHotelId = prefs.getString('user_managed_hotel_id') ?? '';
    }
    notifyListeners();
  }

  // Save session details
  Future<void> login(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = true;
    _isSuperAdmin = userData['isSuperAdmin'] == true;
    _name = userData['name'] ?? '';
    _address = userData['address'] ?? '';
    _mobile = userData['mobile'] ?? '';
    _hotelName = userData['hotelName'] ?? '';
    _roomNumber = userData['roomNumber'] ?? '';
    _email = userData['email'] ?? '';
    _role = userData['role'] ?? 'user';
    _managedHotelId = userData['managedHotelId'] ?? '';

    await prefs.setBool('user_logged_in', true);
    await prefs.setBool('user_is_super_admin', _isSuperAdmin);
    await prefs.setString('user_name', _name);
    await prefs.setString('user_address', _address);
    await prefs.setString('user_mobile', _mobile);
    await prefs.setString('user_hotel_name', _hotelName);
    await prefs.setString('user_room_number', _roomNumber);
    await prefs.setString('user_email', _email);
    await prefs.setString('user_role', _role);
    await prefs.setString('user_managed_hotel_id', _managedHotelId);

    notifyListeners();
  }

  // Clear session details
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    _isSuperAdmin = false;
    _name = '';
    _address = '';
    _mobile = '';
    _hotelName = '';
    _roomNumber = '';
    _email = '';
    _role = 'user';
    _managedHotelId = '';

    await prefs.setBool('user_logged_in', false);
    await prefs.remove('user_is_super_admin');
    await prefs.remove('user_name');
    await prefs.remove('user_address');
    await prefs.remove('user_mobile');
    await prefs.remove('user_hotel_name');
    await prefs.remove('user_room_number');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_managed_hotel_id');

    notifyListeners();
  }
}
