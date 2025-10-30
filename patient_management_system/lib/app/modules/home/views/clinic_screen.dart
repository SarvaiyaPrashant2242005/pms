import 'package:flutter/material.dart';
import 'package:patient_management_system/app/modules/home/views/patient_form.dart';
import 'package:patient_management_system/app/modules/home/views/patient_screen.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/patient_provider.dart';
import '../../../shared/widgets/loader.dart';

class ClinicPage extends StatefulWidget {
  final Map<String, dynamic> clinicData;
  final String clinicId;

  const ClinicPage({
    super.key,
    required this.clinicData,
    required this.clinicId,
  });

  @override
  State<ClinicPage> createState() => _ClinicPageState();
}

class _ClinicPageState extends State<ClinicPage> {
  @override
  void initState() {
    super.initState();
    // Load patients for this clinic when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      patientProvider.loadPatients(widget.clinicId, '');
    });
  }

  void _deletePatient(String patientId, String patientName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Delete Patient',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "$patientName"?',
            style: const TextStyle(color: Colors.black87),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final patientProvider = Provider.of<PatientProvider>(
                  context,
                  listen: false,
                );
                final success = await patientProvider.deletePatient(patientId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Patient deleted successfully'
                            : patientProvider.errorMessage ??
                                  'Failed to delete patient',
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddPatientSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const PatientFormPage(),
    );

    // Refresh patients list after adding
    if (result == true && mounted) {
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      patientProvider.loadPatients(widget.clinicId, '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicName = widget.clinicData['name']?.toString() ?? 'Clinic';
    final address = widget.clinicData['address']?.toString() ?? 'No address';
    final landline = widget.clinicData['landlineNo']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clinicName,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Patients List',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Clinic Info Card
          const SizedBox(height: 20),

          // Patients List
          Expanded(
            child: Consumer<PatientProvider>(
              builder: (context, patientProvider, _) {
                // Show loader while loading
                if (patientProvider.isInitialLoading) {
                  return const Center(child: AppLoader(size: 80));
                }

                // Show error message
                if (patientProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Patients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            patientProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              patientProvider.loadPatients(widget.clinicId, ''),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show empty state
                if (patientProvider.patients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Patients Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add a patient',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show patients list
                return RefreshIndicator(
                  onRefresh: () =>
                      patientProvider.loadPatients(widget.clinicId, ''),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: patientProvider.patients.length,
                    itemBuilder: (context, index) {
                      return _buildPatientCard(patientProvider.patients[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPatientSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final patientId = patient['id']?.toString() ?? '';
    final name = patient['name']?.toString() ?? 'Unknown';
    final gender = patient['gender']?.toString() ?? 'N/A';
    final dob = patient['dob']?.toString() ?? 'N/A';
    final age = patient['age']?.toString() ?? 'N/A';
    final address = patient['address']?.toString() ?? 'N/A';

    // Format DOB if it's in ISO format
    String formattedDob = dob;
    try {
      if (dob.contains('-') && dob.length > 8) {
        final date = DateTime.parse(dob);
        formattedDob =
            '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      }
    } catch (_) {}

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientScreenPage(
              patientData: patient,
              clinicName: widget.clinicData['name']?.toString() ?? 'Clinic',
              clinicData: widget.clinicData,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Gender
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gender.toLowerCase() == 'male'
                          ? Colors.blue.shade50
                          : Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: gender.toLowerCase() == 'male'
                            ? Colors.blue.shade700
                            : Colors.pink.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // DOB and Age
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(Icons.cake, 'DOB: $formattedDob'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoRow(Icons.calendar_today, 'Age: $age'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Address
              _buildInfoRow(
                Icons.location_on,
                address.length > 50
                    ? '${address.substring(0, 50)}...'
                    : address,
              ),
              const SizedBox(height: 10),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.white,
                        builder: (_) => PatientFormPage(patient: patient),
                      );

                      if (result == true && mounted) {
                        final patientProvider = Provider.of<PatientProvider>(
                          context,
                          listen: false,
                        );
                        patientProvider.loadPatients(widget.clinicId, '');
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 5),
                  TextButton.icon(
                    onPressed: () => _deletePatient(patientId, name),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
