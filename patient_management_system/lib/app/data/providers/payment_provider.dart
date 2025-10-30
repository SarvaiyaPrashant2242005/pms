import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_services.dart';

class PaymentProvider extends ChangeNotifier {
  // Reactive state
  bool _loading = false;
  String? _error;

  String? _patientId;
  String _patientName = 'Patient';
  String _doctorName = 'Doctor';

  double _openingBalance = 0;
  double _currentPayment = 0; // today's charges (from latest prescription or passed-in)
  double _amountPayingToday = 0;

  // Razorpay
  Razorpay? _razorpay;
  Completer<bool>? _paymentCompleter;

  // Getters
  bool get loading => _loading;
  String? get error => _error;

  String? get patientId => _patientId;
  String get patientName => _patientName;
  String get doctorName => _doctorName;

  double get openingBalance => _openingBalance;
  double get currentPayment => _currentPayment;
  double get amountPayingToday => _amountPayingToday;
  double get totalPayment => _openingBalance + _currentPayment;
  double get remainingBalance {
    final r = totalPayment - _amountPayingToday;
    return r < 0 ? 0 : r;
  }

  Future<void> loadForPatient({
    required Map<String, dynamic> patient,
    required String doctorName,
    double currentCharges = 0,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _patientId = (patient['mobile'] ?? patient['id'] ?? '').toString();
      _patientName = (patient['name'] ?? 'Patient').toString();
      _doctorName = doctorName.isNotEmpty ? doctorName : 'Doctor';
      _currentPayment = currentCharges;

      final prefs = await SharedPreferences.getInstance();
      final balStr = _patientId == null ? null : prefs.getString('balance_$_patientId');
      _openingBalance = balStr != null ? double.tryParse(balStr) ?? 0 : 0;

      // Reset amount paying today on load
      _amountPayingToday = 0;
      _error = null;
    } catch (e) {
      _error = 'Failed to load payment info';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setAmountPayingToday(String value) {
    final v = double.tryParse(value.trim()) ?? 0;
    _amountPayingToday = v < 0 ? 0 : v;
    notifyListeners();
  }

  // Data coming from UI (Prescription screen) so that on payment success we can create
  // prescription and doses on backend.
  Map<String, dynamic> _pendingCheckupExternal = {};
  List<Map<String, dynamic>> _pendingMedicinesExternal = [];

  void setPendingPrescriptionData({
    required Map<String, dynamic> checkupData,
    required List<Map<String, dynamic>> medicines,
  }) {
    _pendingCheckupExternal = checkupData;
    _pendingMedicinesExternal = medicines;
  }

  Future<bool> confirmPayment({
    required String razorpayKey,
  }) async {
    final checkup = _pendingCheckupExternal.isNotEmpty
        ? _pendingCheckupExternal
        : (_pendingCheckupData ?? {});
    final meds = _pendingMedicinesExternal.isNotEmpty
        ? _pendingMedicinesExternal
        : _pendingMedicines;

    final amt = _amountPayingToday;
    if (amt <= 0) return false;

    return payWithRazorpay(
      checkupData: checkup,
      medicines: meds,
      amountToPay: amt,
      razorpayKey: razorpayKey,
    );
  }

  Future<bool> confirmCashPayment() async {
    final checkup = _pendingCheckupExternal.isNotEmpty
        ? _pendingCheckupExternal
        : (_pendingCheckupData ?? {});
    final meds = _pendingMedicinesExternal.isNotEmpty
        ? _pendingMedicinesExternal
        : _pendingMedicines;

    final amt = _amountPayingToday;
    if (amt <= 0) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingCheckupData = checkup;
      _pendingMedicines = meds;
      _pendingAmount = amt;

      final okLocal = await _persistLocalPayment();

      try {
        await _createPrescriptionAndDoses(
          checkupData: _pendingCheckupData ?? {},
          medicines: _pendingMedicines,
          paymentId: '',
          amountPaid: _pendingAmount,
          paymentMode: 'cash',
        );
      } catch (_) {}

      _loading = false;
      notifyListeners();
      return okLocal;
    } catch (e) {
      _loading = false;
      _error = 'Failed to confirm cash payment';
      notifyListeners();
      return false;
    }
  }

  void _initRazorpayIfNeeded() {
    if (_razorpay != null) return;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  Future<bool> payWithRazorpay({
    required Map<String, dynamic> checkupData,
    required List<Map<String, dynamic>> medicines,
    required double amountToPay,
    required String razorpayKey,
  }) async {
    // amountToPay in INR -> convert to paise
    final int amountPaise = (amountToPay * 100).round();
    if (amountPaise <= 0) return false;

    _initRazorpayIfNeeded();

    _paymentCompleter = Completer<bool>();
    _loading = true;
    _error = null;
    notifyListeners();

    final options = {
      'key': razorpayKey,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'Clinic Payment',
      'description': 'Consultation charges',
      'prefill': {
        'contact': (checkupData['patientMobile'] ?? '').toString(),
        'email': (checkupData['patientEmail'] ?? '').toString(),
        'name': (checkupData['patientName'] ?? _patientName).toString(),
      },
      'notes': {
        'patientId': (_patientId ?? '').toString(),
      },
      'theme': {'color': '#1976D2'},
    };

    try {
      _pendingCheckupData = checkupData;
      _pendingMedicines = medicines;
      _pendingAmount = amountToPay;
      _razorpay!.open(options);
      final ok = await _paymentCompleter!.future;
      _loading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _loading = false;
      _error = 'Failed to initiate payment';
      notifyListeners();
      return false;
    }
  }

  // temp holders for post-payment
  Map<String, dynamic>? _pendingCheckupData;
  List<Map<String, dynamic>> _pendingMedicines = [];
  double _pendingAmount = 0;

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    // 1) persist local payment history/balance
    final ok = await _persistLocalPayment();

    // 2) create prescription and pdose on backend (best-effort)
    try {
      await _createPrescriptionAndDoses(
        checkupData: _pendingCheckupData ?? {},
        medicines: _pendingMedicines,
        paymentId: response.paymentId ?? '',
        amountPaid: _pendingAmount,
        paymentMode: 'online',
      );
    } catch (_) {}

    _paymentCompleter?.complete(ok);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _error = 'Payment failed';
    _paymentCompleter?.complete(false);
    notifyListeners();
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // treat as cancel/no-op
  }

  Future<bool> _persistLocalPayment() async {
    if (_patientId == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final newBalance = remainingBalance;

      await prefs.setString('balance_$_patientId', newBalance.toStringAsFixed(2));

      final historyKey = 'payments_$_patientId';
      final entry = {
        'date': DateTime.now().toIso8601String(),
        'openingBalance': _openingBalance,
        'currentPayment': _currentPayment,
        'amountPaid': _amountPayingToday,
        'remainingBalance': newBalance,
        'doctorName': _doctorName,
      };
      final raw = prefs.getString(historyKey);
      final list = raw != null ? List<Map<String, dynamic>>.from(json.decode(raw)) : <Map<String, dynamic>>[];
      list.add(entry);
      await prefs.setString(historyKey, json.encode(list));

      _openingBalance = newBalance;
      _currentPayment = 0;
      _amountPayingToday = 0;

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Payment success but local save failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> _createPrescriptionAndDoses({
    required Map<String, dynamic> checkupData,
    required List<Map<String, dynamic>> medicines,
    required String paymentId,
    required double amountPaid,
    String paymentMode = 'online',
  }) async {
    try {
      // auth token (optional)
      String? token;
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('authToken');
      } catch (_) {}

      // Prepare prescription body similar to CheckupProvider
      final String? pidStr = (checkupData['patientId'] ?? checkupData['id'])?.toString();
      // Generated bill from checkup data or fallback to current charges tracked in provider
      final String billStr = (checkupData['paymentAmount']?.toString() ??
              checkupData['totalAmount']?.toString() ??
              _currentPayment.toString());
      final double? billAmount = double.tryParse(billStr);

      final Map<String, dynamic> presBody = {
        'patient_id': pidStr != null ? int.tryParse(pidStr) : null,
        'date': checkupData['dateTime'] ?? DateTime.now().toIso8601String(),
        'dieases': checkupData['disease'] ?? checkupData['diagnosis'] ?? '',
        'symptoms': checkupData['symptoms'] ?? '',
        'payment_mode': paymentMode == 'cash' ? 'cash' : 'online',
        'payment_amount': billAmount,
        'paid_amount': amountPaid,
        'payment_ref': paymentId,
      };

      final presResp = await ApiService.post('prescriptions', presBody, token: token);
      int? presId;
      if (presResp is Map) {
        if (presResp['data'] is Map && (presResp['data']['id'] is int)) {
          presId = presResp['data']['id'] as int;
        } else if (presResp['id'] is int) {
          presId = presResp['id'] as int;
        }
      }

      if (presId == null) return; // cannot add doses without pres id

      for (final med in medicines) {
        final doseBody = _prepareDoseData(med, presId.toString());
        try {
          await ApiService.post('pdose', doseBody, token: token);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Map<String, dynamic> _prepareDoseData(Map<String, dynamic> medicine, String? prescriptionId) {
    final bool morning = medicine['morning'] == true || medicine['morning'] == 1;
    final bool afternoon = medicine['afternoon'] == true || medicine['afternoon'] == 1;
    final bool evening = medicine['evening'] == true || medicine['evening'] == 1;
    final bool night = medicine['night'] == true || medicine['night'] == 1;

    String timeOfDay;
    if (morning) {
      timeOfDay = 'morning';
    } else if (afternoon) {
      timeOfDay = 'afternoon';
    } else if (evening || night) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'morning';
    }

    final String uiType = (medicine['type'] ?? 'Tablet').toString();
    final String backendType = uiType.toLowerCase() == 'syrup' ? 'syrup' : 'capsule';

    final int days = int.tryParse('${medicine['days'] ?? '0'}') ?? 0;
    final String mealTiming = (medicine['mealTiming'] ?? 'Before').toString().toLowerCase();

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

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> loadHistory() async {
    if (_patientId == null) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('payments_$_patientId');
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(raw));
    } catch (_) {
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
