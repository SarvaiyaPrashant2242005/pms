import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:patient_management_system/app/data/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String? _currentCheckupKey;

  List<Map<String, dynamic>> get medicines => _medicines;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get errorMessage => _errorMessage;

  // Load medicines for a specific checkup
  Future<void> loadMedicines(String patientMobile, String checkupDate) async {
    _currentCheckupKey = 'medicines_${patientMobile}_$checkupDate';
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final medicinesJson = prefs.getString(_currentCheckupKey!);

      if (medicinesJson != null) {
        final List<dynamic> decoded = json.decode(medicinesJson);
        _medicines = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _medicines = [];
      }

      _isInitialLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load medicines';
      _isInitialLoading = false;
      _medicines = [];
      notifyListeners();
    }
  }

  // Add new medicine to database
  Future<bool> addMedicine(Map<String, dynamic> medicine, {String? prescriptionId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Adding medicine to database...');
      print('Medicine data: $medicine');
      print('Prescription ID: $prescriptionId');

      // Get auth token
      String? token;
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('authToken');
      } catch (_) {}

      // Prepare dose data for API
      final doseData = _prepareDoseData(medicine, prescriptionId);
      print('Dose data to send: $doseData');

      // Call API to save dose
      final response = await ApiService.post(
        'pdose',
        doseData,
        token: token,
      );

      print('API Response: $response');

      // Extract the ID from response and add to medicine
      if (response is Map && response['id'] != null) {
        medicine['id'] = response['id'];
      } else if (response is Map && response['data'] is Map && response['data']['id'] != null) {
        medicine['id'] = response['data']['id'];
      }

      // Add to local list
      _medicines.add(medicine);
      
      // Save to SharedPreferences as backup
      if (_currentCheckupKey != null) {
        await _saveMedicines();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding medicine: $e');
      _errorMessage = 'Failed to add medicine: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add multiple medicines at once
  Future<bool> addMultipleMedicines(
    List<Map<String, dynamic>> medicinesList,
    {String? prescriptionId}
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Adding multiple medicines to database...');
      print('Number of medicines: ${medicinesList.length}');
      print('Prescription ID: $prescriptionId');

      // Get auth token
      String? token;
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('authToken');
      } catch (_) {}

      // Add each medicine to database
      for (var medicine in medicinesList) {
        final doseData = _prepareDoseData(medicine, prescriptionId);
        print('Adding medicine: ${doseData['medicineName']}');

        try {
          final response = await ApiService.post(
            'pdose',
            doseData,
            token: token,
          );

          // Extract the ID from response
          if (response is Map && response['id'] != null) {
            medicine['id'] = response['id'];
          } else if (response is Map && response['data'] is Map && response['data']['id'] != null) {
            medicine['id'] = response['data']['id'];
          }

          print('Medicine added successfully: ${medicine['name']}');
        } catch (e) {
          print('Error adding medicine ${medicine['name']}: $e');
          // Continue with other medicines even if one fails
        }
      }

      // Add to local list
      _medicines.addAll(medicinesList);
      
      // Save to SharedPreferences as backup
      if (_currentCheckupKey != null) {
        await _saveMedicines();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding medicines: $e');
      _errorMessage = 'Failed to add medicines: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Prepare dose data according to backend pDose schema
  // Backend expects: { pres_id, days, medicine_type, medicine_name, time_of_day, meal_time, quantity }
  Map<String, dynamic> _prepareDoseData(
    Map<String, dynamic> medicine,
    String? prescriptionId,
  ) {
    final bool morning = medicine['morning'] == true || medicine['morning'] == 1;
    final bool afternoon = medicine['afternoon'] == true || medicine['afternoon'] == 1;
    final bool evening = medicine['evening'] == true || medicine['evening'] == 1;
    final bool night = medicine['night'] == true || medicine['night'] == 1;

    // Choose a single time_of_day supported by backend enum
    String timeOfDay;
    if (morning) {
      timeOfDay = 'morning';
    } else if (afternoon) {
      timeOfDay = 'afternoon';
    } else if (evening || night) {
      // backend has no 'night', map to 'evening'
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'morning';
    }

    // Map UI type to backend enum
    final String uiType = (medicine['type'] ?? 'Tablet').toString();
    final String backendType = uiType.toLowerCase() == 'syrup' ? 'syrup' : 'capsule';

    // Days and quantity
    final int days = int.tryParse('${medicine['days'] ?? '0'}') ?? 0;
    final String mealTiming = (medicine['mealTiming'] ?? 'Before').toString().toLowerCase();

    // Quantity: for tablets default to 1 piece; for syrup parse ml
    int quantity;
    if (backendType == 'syrup') {
      quantity = int.tryParse('${medicine['quantity'] ?? '5'}') ?? 5;
    } else {
      quantity = 1;
    }

    return {
      'pres_id': int.tryParse('${prescriptionId ?? medicine['prescriptionId'] ?? ''}') ?? 0,
      'days': days,
      'medicine_type': backendType,
      'medicine_name': medicine['name']?.toString() ?? '',
      'time_of_day': timeOfDay,
      'meal_time': mealTiming == 'after' ? 'after' : 'before',
      'quantity': quantity,
    };
  }

  // Build instructions string from medicine data
  String _buildInstructions(Map<String, dynamic> medicine) {
    List<String> instructions = [];
    
    if (medicine['type'] == 'Syrup' && medicine['quantity'] != null) {
      instructions.add('Take ${medicine['quantity']}ml');
    }
    
    List<String> timings = [];
    if (medicine['morning'] == true) timings.add('morning');
    if (medicine['afternoon'] == true) timings.add('afternoon');
    if (medicine['evening'] == true) timings.add('evening');
    if (medicine['night'] == true) timings.add('night');
    
    if (timings.isNotEmpty) {
      instructions.add('Take in ${timings.join(', ')}');
    }
    
    if (medicine['mealTiming'] != null) {
      instructions.add('${medicine['mealTiming']} meal');
    }
    
    if (medicine['days'] != null) {
      instructions.add('Continue for ${medicine['days']} days');
    }
    
    return instructions.join('. ');
  }

  // Update medicine
  Future<bool> updateMedicine(int index, Map<String, dynamic> medicine) async {
    if (_currentCheckupKey == null || index < 0 || index >= _medicines.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _medicines[index] = medicine;
      await _saveMedicines();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update medicine';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete medicine from database
  Future<bool> deleteMedicine(int index) async {
    if (index < 0 || index >= _medicines.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final medicine = _medicines[index];
      final medicineId = medicine['id'];
      
      print('Deleting medicine from database...');
      print('Medicine ID: $medicineId');
      print('Medicine: ${medicine['name']}');

      // Only call API if medicine has an ID (was saved to database)
      if (medicineId != null) {
        // Get auth token
        String? token;
        try {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('authToken');
        } catch (_) {}

        // Call API to delete dose
        final response = await ApiService.delete(
          'pdose/$medicineId',
          token: token,
        );

        print('Delete API Response: $response');
      }

      // Remove from local list
      _medicines.removeAt(index);
      
      // Update SharedPreferences
      if (_currentCheckupKey != null) {
        await _saveMedicines();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting medicine: $e');
      _errorMessage = 'Failed to delete medicine: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save medicines to SharedPreferences
  Future<void> _saveMedicines() async {
    if (_currentCheckupKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final medicinesJson = json.encode(_medicines);
    await prefs.setString(_currentCheckupKey!, medicinesJson);
  }

  // Get medicine by index
  Map<String, dynamic>? getMedicine(int index) {
    if (index < 0 || index >= _medicines.length) return null;
    return _medicines[index];
  }

  // Search medicines by name
  List<Map<String, dynamic>> searchMedicines(String query) {
    if (query.isEmpty) return _medicines;
    
    return _medicines.where((medicine) {
      final name = medicine['name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();
  }

  // Filter medicines by type (Tablet/Syrup)
  List<Map<String, dynamic>> filterByType(String type) {
    return _medicines.where((medicine) {
      return medicine['type']?.toString().toLowerCase() == type.toLowerCase();
    }).toList();
  }

  // Get medicines count
  int get medicinesCount => _medicines.length;

  // Check if medicines list is empty
  bool get isEmpty => _medicines.isEmpty;

  // Check if medicines list is not empty
  bool get isNotEmpty => _medicines.isNotEmpty;

  // Clear medicines (for new checkup or logout)
  void clearMedicines() {
    _medicines = [];
    _currentCheckupKey = null;
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

  // Set medicines directly (useful for initial setup)
  void setMedicines(List<Map<String, dynamic>> medicinesList) {
    _medicines = medicinesList;
    notifyListeners();
  }

  // Get total number of tablets
  int get tabletsCount {
    return _medicines.where((m) => m['type'] == 'Tablet').length;
  }

  // Get total number of syrups
  int get syrupsCount {
    return _medicines.where((m) => m['type'] == 'Syrup').length;
  }

  // Get medicines grouped by timing
  Map<String, List<Map<String, dynamic>>> getMedicinesByTiming() {
    return {
      'morning': _medicines.where((m) => m['morning'] == true).toList(),
      'afternoon': _medicines.where((m) => m['afternoon'] == true).toList(),
      'evening': _medicines.where((m) => m['evening'] == true).toList(),
    };
  }

  // Get medicines by meal timing
  Map<String, List<Map<String, dynamic>>> getMedicinesByMealTiming() {
    return {
      'before': _medicines.where((m) => m['mealTiming'] == 'Before').toList(),
      'after': _medicines.where((m) => m['mealTiming'] == 'After').toList(),
    };
  }

  // Export medicines data (for sharing or printing)
  String exportMedicinesData() {
    if (_medicines.isEmpty) return 'No medicines prescribed';

    final buffer = StringBuffer();
    buffer.writeln('Prescribed Medicines:\n');

    for (int i = 0; i < _medicines.length; i++) {
      final medicine = _medicines[i];
      buffer.writeln('${i + 1}. ${medicine['name']} (${medicine['type']})');
      buffer.writeln('   Duration: ${medicine['days']} days');
      
      final timings = <String>[];
      if (medicine['morning'] == true) timings.add('Morning');
      if (medicine['afternoon'] == true) timings.add('Afternoon');
      if (medicine['evening'] == true) timings.add('Evening');
      buffer.writeln('   Timing: ${timings.join(', ')}');
      buffer.writeln('   ${medicine['mealTiming']} Meal');
      buffer.writeln('');
    }

    return buffer.toString();
  }
}