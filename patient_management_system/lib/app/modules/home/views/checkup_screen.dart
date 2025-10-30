import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'medicine_screen.dart';

class CheckupScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String clinicName;
  final String clinicCharges;

  const CheckupScreen({
    super.key,
    required this.patientData,
    required this.clinicName,
    required this.clinicCharges,
  });

  @override
  State<CheckupScreen> createState() => _CheckupScreenState();
}

class _CheckupScreenState extends State<CheckupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _diseaseController = TextEditingController();
  late DateTime _selectedDateTime;

  // List to store selected symptoms
  final List<String> _selectedSymptoms = [];

  // Common symptoms list for typeahead
  final List<String> _commonSymptoms = [
    'Fever',
    'Cough',
    'Cold',
    'Headache',
    'Body Pain',
    'Sore Throat',
    'Runny Nose',
    'Fatigue',
    'Nausea',
    'Vomiting',
    'Diarrhea',
    'Stomach Pain',
    'Chest Pain',
    'Shortness of Breath',
    'Dizziness',
    'Loss of Appetite',
    'Weakness',
    'Chills',
    'Sweating',
    'Joint Pain',
    'Muscle Pain',
    'Back Pain',
    'Skin Rash',
    'Itching',
    'Sneezing',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _addSymptom(String symptom) {
    if (symptom.trim().isNotEmpty &&
        !_selectedSymptoms.contains(symptom.trim())) {
      setState(() {
        _selectedSymptoms.add(symptom.trim());
      });
      _symptomsController.clear();
    }
  }

  void _removeSymptom(String symptom) {
    setState(() {
      _selectedSymptoms.remove(symptom);
    });
  }

  // Add this to your CheckupScreen where you handle the "Next" button
  // Update the _handleNext method or wherever you're saving the checkup

  void _handleNext() {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one symptom'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final checkupData = {
        'patientId':
            widget.patientData['id'], // Make sure to include patient ID
        'patientName': widget.patientData['name'],
        'patientMobile': widget.patientData['mobile'],
        'patientAge': widget.patientData['age'],
        'patientGender': widget.patientData['gender'],
        'dateTime': _selectedDateTime.toIso8601String(),
        'symptoms': _selectedSymptoms.join(', '),
        'disease': _diseaseController.text.trim(),
        'clinicName': widget.clinicName,
        'clinicCharges': widget.clinicCharges,
      };

      print('Checkup Data with Patient ID: $checkupData');

      // Navigate to Medicine Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicineScreen(checkupData: checkupData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Patient Checkup',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Details Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Name',
                        widget.patientData['name'] ?? 'N/A',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Mobile',
                        widget.patientData['contact'] ?? 'N/A',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.cake_outlined,
                              'Age',
                              widget.patientData['age']?.toString() ?? 'N/A',
                            ),
                          ),
                          Expanded(
                            child: _buildInfoRow(
                              Icons.wc_outlined,
                              'Gender',
                              widget.patientData['gender'] ?? 'N/A',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date and Time Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checkup Date & Time',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 15,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_selectedDateTime),
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat(
                                        'hh:mm a',
                                      ).format(_selectedDateTime),
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Symptoms',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TypeAheadField<String>(
                controller: _symptomsController,
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Type to search symptoms...',
                      prefixIcon: const Icon(
                        Icons.medical_information_outlined,
                        color: Colors.blue,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () {
                          if (_symptomsController.text.trim().isNotEmpty) {
                            _addSymptom(_symptomsController.text.trim());
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onFieldSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _addSymptom(value.trim());
                      }
                    },
                  );
                },
                suggestionsCallback: (pattern) {
                  // Show all symptoms when field is empty (user just focused)
                  if (pattern.isEmpty) return _commonSymptoms;
                  // Filter symptoms based on user input
                  return _commonSymptoms
                      .where(
                        (symptom) => symptom.toLowerCase().contains(
                          pattern.toLowerCase(),
                        ),
                      )
                      .toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    leading: const Icon(
                      Icons.medical_services,
                      color: Colors.blue,
                      size: 20,
                    ),
                    title: Text(suggestion),
                    dense: true,
                  );
                },
                onSelected: (suggestion) {
                  _addSymptom(suggestion);
                },
                decorationBuilder: (context, child) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                constraints: const BoxConstraints(maxHeight: 300),
                offset: const Offset(0, 4),
              ),
              const SizedBox(height: 12),

              // Display selected symptoms as chips
              if (_selectedSymptoms.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSymptoms.map((symptom) {
                      return Chip(
                        label: Text(symptom),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeSymptom(symptom),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue.shade300),
                        labelStyle: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),

              // Disease/Diagnosis Field
              const Text(
                'Disease / Diagnosis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _diseaseController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter diagnosis or disease name...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(
                      Icons.local_hospital_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter disease or diagnosis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}
