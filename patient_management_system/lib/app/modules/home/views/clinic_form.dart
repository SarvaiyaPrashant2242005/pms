import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/clinic_provider.dart';
import '../../../shared/widgets/loader.dart';

class ClinicFormPage extends StatefulWidget {
  final Map<String, dynamic>? clinic; // Changed from String to dynamic
  final String? clinicId; // Changed from index to clinic ID

  const ClinicFormPage({super.key, this.clinic, this.clinicId});

  @override
  State<ClinicFormPage> createState() => _ClinicFormPageState();
}

class _ClinicFormPageState extends State<ClinicFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _landlineController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _chargesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.clinic != null) {
      _clinicNameController.text = widget.clinic!['name']?.toString() ?? '';
      _landlineController.text = widget.clinic!['landlineNo']?.toString() ?? '';
      _doctorNameController.text =
          widget.clinic!['doctorName']?.toString() ?? '';
      _addressController.text = widget.clinic!['address']?.toString() ?? '';
      _chargesController.text =
          widget.clinic!['price_per_day']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _landlineController.dispose();
    _doctorNameController.dispose();
    _addressController.dispose();
    _chargesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final clinicProvider = Provider.of<ClinicProvider>(context, listen: false);

    // Prepare data matching backend schema
    final clinicData = {
      'name': _clinicNameController.text.trim(),
      'landlineNo': _landlineController.text.trim(),
      'doctorName': _doctorNameController.text.trim(),
      'address': _addressController.text.trim(),
      'price_per_day': int.parse(_chargesController.text.trim()),
    };

    setState(() => _isSubmitting = true);

    bool success;
    if (widget.clinic != null && widget.clinicId != null) {
      // Update existing clinic
      success = await clinicProvider.updateClinic(widget.clinicId!, clinicData);
    } else {
      // Add new clinic
      success = await clinicProvider.addClinic(clinicData);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.clinic != null
                ? 'Clinic updated successfully'
                : 'Clinic added successfully',
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
      final errMsg =
          clinicProvider.errorMessage ??
          'Failed to save clinic. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg, textAlign: TextAlign.center),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                widget.clinic != null
                    ? 'Update Clinic Details'
                    : 'Add New Clinic',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildLabel("Clinic Name", true),
            const SizedBox(height: 5),
            TextFormField(
              controller: _clinicNameController,
              decoration: _buildDecoration(
                hint: "Enter clinic name",
                icon: Icons.local_hospital_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Clinic name is required'
                  : null,
            ),
            const SizedBox(height: 12),

            _buildLabel("Landline Number", true),
            const SizedBox(height: 5),
            TextFormField(
              controller: _landlineController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\-\s\(\)]')),
              ],
              decoration: _buildDecoration(
                hint: "Enter landline number",
                icon: Icons.phone_outlined,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Landline is required' : null,
            ),
            const SizedBox(height: 12),

            _buildLabel("Doctor Name", true),
            const SizedBox(height: 5),
            TextFormField(
              controller: _doctorNameController,
              decoration: _buildDecoration(
                hint: "Enter doctor name",
                icon: Icons.person_outline,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Doctor name is required'
                  : null,
            ),
            const SizedBox(height: 12),

            _buildLabel("Address", true),
            const SizedBox(height: 5),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: _buildDecoration(
                hint: "Enter full clinic address",
                icon: Icons.location_on_outlined,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),

            _buildLabel("Consultation Charges (Max: ₹1000)", true),
            const SizedBox(height: 5),
            TextFormField(
              controller: _chargesController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: _buildDecoration(
                hint: "Enter consultation charges (Max: 1000)",
                icon: Icons.currency_rupee_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Charges are required';
                }
                final amount = int.tryParse(v.trim());
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > 1000) {
                  return 'Charges cannot exceed ₹1000';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),

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
                        widget.clinic != null ? 'Update Clinic' : 'Add Clinic',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w600,
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

  InputDecoration _buildDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blue),
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
      errorMaxLines: 2,
    );
  }
}
