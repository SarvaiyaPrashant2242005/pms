import 'package:flutter/foundation.dart';
import 'package:patient_management_system/app/data/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String demoEmail = 'demo@medtrack.com';
  static const String demoPassword = 'demo123';
  static const String demoName = 'Dr. Rajesh Kumar';

  bool _isLoading = false;
  String? _errorMessage;
  String? _userEmail;
  String? _userName;
  bool _isLoggedIn = false;
  String? _token;
  String? _doctorId;
  String? _degree;
  String? _phoneNo;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get doctorId => _doctorId;
  String? get degree => _degree;
  String? get phoneNo => _phoneNo;

  // Set loader
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Load user if already logged in
  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _token = prefs.getString('token');
      _userEmail = prefs.getString('email');
      _userName = prefs.getString('userName');
      _doctorId = prefs.getString('doctorId');
      _degree = prefs.getString('degree');
      _phoneNo = prefs.getString('phoneNo');
      _isLoggedIn = isLoggedIn && _token != null;
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Signup logic...
  Future<bool> signUpUser(
    String name,
    String email,
    String password, {
    String degree = '',
    String phoneNo = '',
  }) async {
    setLoading(true);
    _errorMessage = null;

    try {
      final response = await ApiService.post('doctor/register', {
        'fullname': name,
        'email': email,
        'password': password,
        'degree': degree,
        'phoneNo': phoneNo,
      });

      if (response != null && response['doctorId'] != null) {
        // Auto-login after successful registration
        final loggedIn = await login(email, password);
        setLoading(false);
        return loggedIn;
      }
      _errorMessage = 'Registration failed';
      setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
      setLoading(false);
      return false;
    }
  }

  //Login logic...
  Future<bool> login(String email, String password) async {
    setLoading(true);
    _errorMessage = null;

    try {
      final response = await ApiService.post('doctor/login', {
        'email': email,
        'password': password,
      });

      _token = response['token'];
      final doctor = response['doctor'];

      if (_token == null || doctor == null) {
        _errorMessage = 'Invalid server response';
        setLoading(false);
        return false;
      }

      _userEmail = doctor['email'];
      _userName = doctor['fullname'];
      _doctorId = doctor['_id']?.toString() ?? doctor['id']?.toString();
      _degree = doctor['degree']?.toString();
      _phoneNo = doctor['phoneNo']?.toString();
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('email', _userEmail!);
      await prefs.setString('userName', _userName!);
      if (_doctorId != null) {
        await prefs.setString('doctorId', _doctorId!);
      }
      if (_degree != null) {
        await prefs.setString('degree', _degree!);
      }
      if (_phoneNo != null) {
        await prefs.setString('phoneNo', _phoneNo!);
      }
      await prefs.setBool('isLoggedIn', true);

      setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;

      setLoading(false);
      return false;
    }
  }

  // Update profile data on server and locally
  Future<bool> updateProfile({String? fullname, String? degree, String? phoneNo}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = _token ?? prefs.getString('token');
      final id = _doctorId ?? prefs.getString('doctorId');

      if (token == null || id == null) {
        _errorMessage = 'Not authenticated';
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> payload = {};
      if (fullname != null) payload['fullname'] = fullname;
      if (degree != null) payload['degree'] = degree;
      if (phoneNo != null) payload['phoneNo'] = phoneNo;

      await ApiService.put('doctor/profile/$id', payload, token: token);

      if (fullname != null) {
        _userName = fullname;
        await prefs.setString('userName', fullname);
      }
      if (degree != null) {
        _degree = degree;
        await prefs.setString('degree', degree);
      }
      if (phoneNo != null) {
        _phoneNo = phoneNo;
        await prefs.setString('phoneNo', phoneNo);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Logout Logic...
  Future<void> logOutUser() async {
    setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _userName = null;
      _userEmail = null;
      _isLoggedIn = false;
      _errorMessage = null;
      _token = null;
      _doctorId = null;

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}