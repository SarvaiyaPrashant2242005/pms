import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:patient_management_system/app/data/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckupProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _checkups = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentPatientKey;

  List<Map<String, dynamic>> get checkups => _checkups;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Load checkups for specific patient
  Future<void> loadCheckups(
    String patientMobile,
    String clinicName,
    String userEmail,
  ) async {
    _currentPatientKey = 'checkups_${userEmail}_${clinicName}_$patientMobile';
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final checkupsJson = prefs.getString(_currentPatientKey!);

      if (checkupsJson != null) {
        final List<dynamic> decoded = json.decode(checkupsJson);
        _checkups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _checkups = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load checkups';
      _isLoading = false;
      _checkups = [];
      notifyListeners();
    }
  }

  // Add new checkup and save to database
  // Returns newly created prescription ID on success, or null on failure
  Future<int?> addCheckup(
    Map<String, dynamic> checkup, {
    String? patientId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Adding checkup to database...');
      print('Checkup data: $checkup');
      print('Patient ID: $patientId');

      // Get auth token
      String? token;
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('authToken');
      } catch (_) {}

      // Prepare prescription data for API (align with backend schema)
      final prescriptionData = _preparePrescriptionData(checkup, patientId);
      print('Prescription data to send: $prescriptionData');

      // Call API to save prescription
      final response = await ApiService.post(
        'prescriptions',
        prescriptionData,
        token: token,
      );

      print('API Response: $response');

      // Extract created prescription id from response
      int? createdId;
      if (response is Map) {
        if (response['data'] is Map && (response['data']['id'] is int)) {
          createdId = response['data']['id'] as int;
        } else if (response['id'] is int) {
          createdId = response['id'] as int;
        }
      }

      // Add to local list for UI/history
      _checkups.add(checkup);

      // Save to SharedPreferences as backup
      if (_currentPatientKey != null) {
        await _saveCheckups();
      }

      _isLoading = false;
      notifyListeners();
      return createdId; // may be null if response shape unexpected
    } catch (e) {
      print('Error adding checkup: $e');
      _errorMessage = 'Failed to add checkup: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Prepare prescription data according to API schema
  // Backend expects: { patient_id, date, dieases, symptoms, payment_mode, payment_amount, paid_amount }
  Map<String, dynamic> _preparePrescriptionData(
    Map<String, dynamic> checkup,
    String? patientId,
  ) {
    // Map to backend keys
    final pid = (patientId ?? checkup['patientId'])?.toString();
    final paymentAmountStr =
        checkup['paymentAmount']?.toString() ??
        checkup['totalAmount']?.toString() ??
        '0';
    final paymentAmount = double.tryParse(paymentAmountStr);

    return {
      'patient_id': pid != null ? int.tryParse(pid) : null,
      'date': checkup['dateTime'] ?? DateTime.now().toIso8601String(),
      'dieases': checkup['disease'] ?? checkup['diagnosis'] ?? '',
      'symptoms': checkup['symptoms'] ?? '',
      'payment_mode': checkup['paymentMode'] ?? 'cash',
      'payment_amount': paymentAmount,
      'paid_amount': 0,
    };
  }

  // Save checkups to SharedPreferences
  Future<void> _saveCheckups() async {
    if (_currentPatientKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final checkupsJson = json.encode(_checkups);
    await prefs.setString(_currentPatientKey!, checkupsJson);
  }

  // Clear checkups
  void clearCheckups() {
    _checkups = [];
    _currentPatientKey = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
