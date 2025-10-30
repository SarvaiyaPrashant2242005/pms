import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patient_management_system/app/data/services/api_services.dart';

class PatientProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String? _currentClinicId;

  List<Map<String, dynamic>> get patients => _patients;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get errorMessage => _errorMessage;

  // Load patients for specific clinic from backend
  Future<void> loadPatients(String clinicId, String s) async {
    _currentClinicId = clinicId;
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await ApiService.get(
        'patient/clinic/$clinicId',
        token: token,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        _patients = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _patients = [];
        _errorMessage = response['message'] ?? 'No patients found';
      }

      _isInitialLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load patients: ${e.toString()}';
      _isInitialLoading = false;
      _patients = [];
      notifyListeners();
    }
  }

  // Load patients for specific doctor from backend
  Future<void> loadPatientsByDoctorId() async {
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final doctorId = prefs.getString('doctorId');

      if (doctorId == null || doctorId.isEmpty) {
        _patients = [];
        _errorMessage = 'Doctor ID not found';
        _isInitialLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.get(
        'patient/doctor/$doctorId',
        token: token,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _patients = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _patients = [];
        _errorMessage = response['message'] ?? 'No patients found';
      }

      _isInitialLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load patients: ${e.toString()}';
      _isInitialLoading = false;
      _patients = [];
      notifyListeners();
    }
  }

  // Add new patient
  Future<bool> addPatient(Map<String, dynamic> patientData) async {
    if (_currentClinicId == null) {
      _errorMessage = 'Clinic ID not found';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final doctorId = prefs.getString('doctorId');

      if (doctorId == null) {
        _errorMessage = 'Doctor ID not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add doctorId and clinicId to patient data
      final dataToSend = {
        ...patientData,
        'doctorId': doctorId,
        'clinicId': _currentClinicId,
      };

      final response = await ApiService.post(
        'patient',
        dataToSend,
        token: token,
      );

      if (response['success'] == true) {
        // Add the new patient to local list
        _patients.add(response['data']);
        
        // Optionally store patient ID
        final patientId = response['data']['id']?.toString();
        if (patientId != null) {
          await prefs.setString('lastPatientId', patientId);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to add patient';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error adding patient: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update patient
  Future<bool> updatePatient(String patientId, Map<String, dynamic> patientData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await ApiService.put(
        'patient/$patientId',
        patientData,
        token: token,
      );

      if (response['success'] == true) {
        // Update patient in local list
        final index = _patients.indexWhere((p) => p['id'].toString() == patientId);
        if (index != -1) {
          _patients[index] = response['data'];
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update patient';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating patient: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete patient
  Future<bool> deletePatient(String patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await ApiService.delete(
        'patient/$patientId',
        token: token,
      );

      if (response['success'] == true) {
        // Remove patient from local list
        _patients.removeWhere((p) => p['id'].toString() == patientId);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete patient';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting patient: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear patients (for logout or clinic change)
  void clearPatients() {
    _patients = [];
    _currentClinicId = null;
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