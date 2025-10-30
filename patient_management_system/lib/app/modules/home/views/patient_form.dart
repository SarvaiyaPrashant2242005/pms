import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/patient_provider.dart';
import '../../../shared/widgets/loader.dart';

class PatientFormPage extends StatefulWidget {
  final Map<String, dynamic>? patient; // For editing existing patient

  const PatientFormPage({super.key, this.patient, int? patientIndex});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender;
  bool _isSubmitting = false;
  DateTime? _selectedDob;
  String? _patientId; // Store patient ID for updates

  @override
  void initState() {
    super.initState();

    // If editing existing patient
    if (widget.patient != null) {
      _patientId = widget.patient!['id']?.toString();
      _nameController.text = widget.patient!['name'] ?? '';
      _mobileController.text = widget.patient!['contact'] ?? '';

      // Handle DOB from backend (might be in ISO format)
      final dobStr = widget.patient!['dob'] ?? '';
      if (dobStr.isNotEmpty) {
        try {
          // Try parsing ISO format first (from backend)
          _selectedDob = DateTime.parse(dobStr);
          _dobController.text = DateFormat('dd-MM-yyyy').format(_selectedDob!);
        } catch (_) {
          // Try parsing display format
          try {
            _selectedDob = DateFormat('dd-MM-yyyy').parse(dobStr);
            _dobController.text = dobStr;
          } catch (_) {
            // If all fails, leave empty
          }
        }
      }

      _gender = widget.patient!['gender'];
      _ageController.text = widget.patient!['age']?.toString() ?? '';
      _addressController.text = widget.patient!['address']?.toString() ?? '';
      _heightController.text = widget.patient!['height']?.toString() ?? '';
      _weightController.text = widget.patient!['weight']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Calculate age from DOB
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  // Show date picker for DOB
  Future<void> _selectDob() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
        // Auto-calculate and set age
        _ageController.text = _calculateAge(picked).toString();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );

    // Convert DOB to ISO format for backend (YYYY-MM-DD)
    String dobForBackend = '';
    if (_selectedDob != null) {
      dobForBackend = DateFormat('yyyy-MM-dd').format(_selectedDob!);
    }

    // Prepare patient data matching backend schema
    final patientData = {
      'name': _nameController.text.trim(),
      'contact': _mobileController.text.trim(),
      'dob': dobForBackend,
      'age': _ageController.text.trim().isEmpty
          ? null
          : int.tryParse(_ageController.text.trim()),
      'gender': _gender ?? '',
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'height': _heightController.text.trim().isEmpty
          ? null
          : _heightController.text.trim(),
      'weight': _weightController.text.trim().isEmpty
          ? null
          : _weightController.text.trim(),
      'photo': null, // Can be added later for image upload
    };

    setState(() => _isSubmitting = true);

    bool success;
    if (widget.patient != null && _patientId != null) {
      // Update existing patient
      success = await patientProvider.updatePatient(_patientId!, patientData);
    } else {
      // Add new patient
      success = await patientProvider.addPatient(patientData);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.patient != null
                ? 'Patient updated successfully'
                : 'Patient added successfully',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final errorMsg =
          patientProvider.errorMessage ??
          'Failed to save patient. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 15.0,
            right: 15.0,
            top: 15.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 15.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.patient != null
                      ? 'Update Patient Details'
                      : 'Add New Patient',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.patient != null
                      ? 'Edit the patient information below'
                      : 'Fill in the patient information below',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Name
                _buildLabel("Full Name", isRequired: true),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  decoration: _buildInputDecoration(
                    hintText: 'Enter patient name',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
                      return 'Only alphabets and spaces allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Mobile
                _buildLabel("Mobile Number", isRequired: true),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _buildInputDecoration(
                    hintText: 'Enter mobile number',
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Mobile number is required';
                    }
                    if (v.length != 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // DOB and Age in one row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Date of Birth", isRequired: true),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: _selectDob,
                            decoration: _buildInputDecoration(
                              hintText: 'DD-MM-YYYY',
                              prefixIcon: Icons.cake_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'DOB is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Age", isRequired: true),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            readOnly: _dobController.text.isNotEmpty,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: _buildInputDecoration(
                              hintText: 'Age',
                              prefixIcon: Icons.calendar_today_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Age is required';
                              }
                              final age = int.tryParse(v);
                              if (age == null || age < 0 || age > 150) {
                                return 'Invalid age';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Gender
                _buildLabel("Gender", isRequired: true),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _buildInputDecoration(
                    hintText: 'Select gender',
                    prefixIcon: Icons.wc_outlined,
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => _gender = val),
                  validator: (v) => v == null ? 'Please select gender' : null,
                ),
                const SizedBox(height: 10),

                // Address
                _buildLabel("Address", isRequired: false),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter patient address',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  validator: (v) {
                    if (v != null && v.length > 500) {
                      return 'Address must not exceed 500 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Height and Weight in one row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Height (cm)", isRequired: false),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: _buildInputDecoration(
                              hintText: 'Height',
                              prefixIcon: Icons.height_outlined,
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final height = int.tryParse(v);
                                if (height == null || height > 1000) {
                                  return 'Max 1000 cm';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Weight (kg)", isRequired: false),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: _buildInputDecoration(
                              hintText: 'Weight',
                              prefixIcon: Icons.monitor_weight_outlined,
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final weight = int.tryParse(v);
                                if (weight == null || weight > 1000) {
                                  return 'Max 1000 kg';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Submit button
                SizedBox(
                  height: 50,
                  child: _isSubmitting
                      ? const AppLoader(size: 40)
                      : ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.patient != null
                                ? 'Update Patient'
                                : 'Add Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: Colors.blue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
