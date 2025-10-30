import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';

class ClinicProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String? _currentDoctorId;

  List<Map<String, dynamic>> get clinics => _clinics;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get errorMessage => _errorMessage;

  // Load clinics for specific doctor from backend
  Future<void> loadClinics() async {
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get doctor ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentDoctorId = prefs.getString('doctorId');

      if (_currentDoctorId == null) {
        _errorMessage = 'Doctor ID not found. Please login again.';
        _isInitialLoading = false;
        notifyListeners();
        return;
      }

      // Get token for authentication
      final token = prefs.getString('token');

      // Fetch clinics from backend by doctor ID
      final response = await ApiService.get(
        'clinics/doctors/$_currentDoctorId',
        token: token,
      );

      if (response['success'] == true) {
        final List<dynamic> clinicsData = response['data'] ?? [];
        _clinics = clinicsData.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load clinics';
        _clinics = [];
      }

      _isInitialLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load clinics: ${e.toString()}';
      _isInitialLoading = false;
      _clinics = [];
      notifyListeners();
    }
  }

  // Add new clinic
  Future<bool> addClinic(Map<String, dynamic> clinicData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      _currentDoctorId = prefs.getString('doctorId');

      if (_currentDoctorId == null) {
        _errorMessage = 'Doctor ID not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add doctor_id to clinic data
      final dataToSend = {
        ...clinicData,
        'doctor_id': _currentDoctorId,
      };

      final response = await ApiService.post(
        'clinics',
        dataToSend,
        token: token,
      );

      if (response['success'] == true) {
        // Add the new clinic to local list
        _clinics.add(response['data']);
        
        // Store clinic ID in SharedPreferences
        final clinicId = response['data']['id']?.toString();
        if (clinicId != null) {
          await prefs.setString('clinicId', clinicId);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to add clinic';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error adding clinic: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update clinic
  Future<bool> updateClinic(String clinicId, Map<String, dynamic> clinicData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await ApiService.put(
        'clinics/$clinicId',
        clinicData,
        token: token,
      );

      if (response['success'] == true) {
        // Update the clinic in local list
        final index = _clinics.indexWhere((c) => c['id'].toString() == clinicId);
        if (index != -1) {
          _clinics[index] = response['data'];
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update clinic';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update clinic: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete clinic
  Future<bool> deleteClinic(String clinicId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await ApiService.delete(
        'clinics/$clinicId',
        token: token,
      );

      if (response['success'] == true) {
        // Remove the clinic from local list
        _clinics.removeWhere((c) => c['id'].toString() == clinicId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete clinic';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete clinic: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear clinics (for logout)
  void clearClinics() {
    _clinics = [];
    _currentDoctorId = null;
    _isLoading = false;
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}