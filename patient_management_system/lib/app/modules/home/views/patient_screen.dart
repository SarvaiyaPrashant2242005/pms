import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:patient_management_system/app/data/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'checkup_screen.dart';
import 'payment_screen.dart';
import 'package:provider/provider.dart';
import 'package:patient_management_system/app/data/providers/payment_provider.dart';

class PatientScreenPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final String clinicName;
  final Map<String, dynamic> clinicData;

  const PatientScreenPage({
    super.key,
    required this.patientData,
    required this.clinicName,
    required this.clinicData,
  });

  @override
  Widget build(BuildContext context) {
    final patient = patientData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          patient['name'] ?? 'Patient Details',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Patient Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow("👤 Name", patient['name'] ?? 'N/A'),
                    _buildDetailRow("📞 Mobile", patient['contact'] ?? 'N/A'),
                    _buildDetailRow(
                      "🎂 Age",
                      patient['age']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow("⚧ Gender", patient['gender'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  "Checkup",
                  Icons.medical_services_outlined,
                  Colors.blue,
                  onTap: () {
                    if (!_ensureValidNameOrNotify(context)) return;
                    final charges =
                        clinicData['price_per_day'] ??
                        clinicData['charges'] ??
                        '500';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckupScreen(
                          patientData: patientData,
                          clinicName: clinicName,
                          clinicCharges: charges,
                        ),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  "Payment",
                  Icons.payment_outlined,
                  Colors.green,
                  onTap: () async {
                    if (!_ensureValidNameOrNotify(context)) return;
                    final mobile = patient['mobile'] ?? '';
                    double currentCharges = 0;
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final raw = prefs.getString('prescriptions_$mobile');
                      if (raw != null) {
                        final List<dynamic> decoded = json.decode(raw);
                        if (decoded.isNotEmpty) {
                          final latest = Map<String, dynamic>.from(
                            decoded.first,
                          );
                          final amt = double.tryParse(
                            (latest['totalAmount'] ?? '0').toString(),
                          );
                          if (amt != null) currentCharges = amt;
                        }
                      }
                    } catch (_) {}

                    String doctorName = 'Doctor';
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      doctorName = prefs.getString('userName') ?? doctorName;
                    } catch (_) {}

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => PaymentProvider(),
                          child: PatientPaymentPage(
                            patient: patientData,
                            doctorName: doctorName,
                            currentCharges: currentCharges,
                            medicines: const <Map<String, dynamic>>[],
                            checkupData: const <String, dynamic>{},
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  "Lab Test",
                  Icons.science_outlined,
                  Colors.orange,
                  onTap: () {
                    if (!_ensureValidNameOrNotify(context)) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lab Test clicked")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Prescription History Inline
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: const [
                  Icon(Icons.history, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Prescription History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadPrescriptionsFromApi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load prescriptions',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.error.toString().replaceAll(
                            'Exception: ',
                            '',
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                final prescriptions = snapshot.data ?? [];
                if (prescriptions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No prescription history found',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    return _buildPrescriptionCard(
                      prescriptions[index],
                      context,
                      index + 1, // Pass the sequential number (1-based)
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // New method to load prescriptions from API
  Future<List<Map<String, dynamic>>> _loadPrescriptionsFromApi() async {
    try {
      final patientId = patientData['id'];
      print('Loading prescriptions for patient ID: $patientId');
      if (patientId == null) {
        throw Exception('Patient ID not found');
      }

      // Get auth token if needed
      String? token;
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('authToken');
      } catch (_) {}

      // Call the API
      final response = await ApiService.get(
        'prescriptions/patient/$patientId',
        token: token,
      );

      // Debug: Print the raw response
      print('API Response: $response');
      print('Response type: ${response.runtimeType}');

      // Parse response
      List<Map<String, dynamic>> prescriptions = [];

      if (response is List) {
        prescriptions = response
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response is Map && response['prescriptions'] is List) {
        prescriptions = (response['prescriptions'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response is Map && response['data'] is List) {
        prescriptions = (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response is Map) {
        // Try to find any array field in the response
        for (var key in response.keys) {
          if (response[key] is List) {
            print('Found list in key: $key');
            prescriptions = (response[key] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            break;
          }
        }
      }

      print('Parsed ${prescriptions.length} prescriptions');
      return prescriptions;
    } catch (e) {
      print('Error loading prescriptions: $e');
      throw Exception('Failed to load prescriptions: ${e.toString()}');
    }
  }

  bool _isValidName(String name) {
    final reg = RegExp(r'^[A-Za-z .]+$');
    return reg.hasMatch(name);
  }

  bool _ensureValidNameOrNotify(BuildContext context) {
    final name = patientData['name'] ?? '';
    if (name.isEmpty || !_isValidName(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure patient has a valid name'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(
    Map<String, dynamic> prescription,
    BuildContext context,
    int sequentialNumber, // Add sequential number parameter
  ) {
    // Debug: Print the prescription data to see what fields are available
    print('Prescription data: $prescription');

    // Try multiple possible date field names
    final date =
        prescription['date'] ??
        prescription['createdAt'] ??
        prescription['created_at'] ??
        prescription['updatedAt'] ??
        prescription['updated_at'] ??
        null;

    final disease =
        prescription['disease'] ?? prescription['diseases'] ?? 'N/A';

    final medicines =
        (prescription['doses'] as List?) ??
        (prescription['medicines'] as List?) ??
        [];

    final amount =
        prescription['totalAmount'] ??
        prescription['total_amount'] ??
        prescription['amount'] ??
        '0';

    final paymentAmount =
        prescription['paymentAmount'] ??
        prescription['payment_amount'] ??
        amount;

    // Debug: Print payment amount
    print(
      'Prescription payment_amount from DB: ${prescription['payment_amount']}',
    );
    print(
      'Prescription paymentAmount from DB: ${prescription['paymentAmount']}',
    );
    print('Final paymentAmount used: $paymentAmount');

    String formattedDate;
    if (date != null) {
      try {
        final parsedDate = DateTime.parse(date);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
      } catch (e) {
        print('Date parsing error: $e');
        formattedDate = date.toString();
      }
    } else {
      // If no date available, show sequential number
      formattedDate = 'Prescription $sequentialNumber';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medication, color: Colors.blue),
        ),
        title: Text(
          formattedDate,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disease: $disease',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${medicines.length} medicine(s) • ₹$paymentAmount',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...medicines.map((med) {
                  final medMap = med is Map
                      ? Map<String, dynamic>.from(med)
                      : <String, dynamic>{};
                  final name =
                      medMap['medicine_name'] ??
                      medMap['name'] ??
                      medMap['medicineName'] ??
                      'Unknown';
                  final days = medMap['days']?.toString() ?? '';
                  final quantity = medMap['quantity']?.toString() ?? '';
                  final timeOfDay = medMap['time_of_day']?.toString() ?? '';
                  final mealTime = medMap['meal_time']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (days.isNotEmpty)
                                Text(
                                  'Days: $days',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              if (quantity.isNotEmpty)
                                Text(
                                  'Qty: $quantity',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              if (timeOfDay.isNotEmpty || mealTime.isNotEmpty)
                                Text(
                                  [
                                    if (timeOfDay.isNotEmpty) timeOfDay,
                                    if (mealTime.isNotEmpty) '$mealTime meal',
                                  ].join(' • '),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 24),
                const Text(
                  'Payment Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '₹$paymentAmount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
