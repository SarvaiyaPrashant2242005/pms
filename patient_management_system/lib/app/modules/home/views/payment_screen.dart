import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:patient_management_system/app/data/providers/payment_provider.dart';

class PatientPaymentPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  final String doctorName;
  final double currentCharges; // today's charges (can be 0 if first time)
  final Map<String, dynamic>? checkupData;
  final List<Map<String, dynamic>>? medicines;

  const PatientPaymentPage({
    super.key,
    required this.patient,
    required this.doctorName,
    this.currentCharges = 0,
    this.checkupData,
    this.medicines,
  });

  @override
  State<PatientPaymentPage> createState() => _PatientPaymentPageState();
}

class _PatientPaymentPageState extends State<PatientPaymentPage> {
  final TextEditingController _payingController = TextEditingController();
  String _paymentMode = 'cash'; // 'cash' or 'online'

  String get _patientId => (widget.patient['mobile'] ?? widget.patient['id'] ?? '').toString();
  String get _patientName => (widget.patient['name'] ?? 'Patient').toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      provider.loadForPatient(
        patient: widget.patient,
        doctorName: widget.doctorName,
        currentCharges: widget.currentCharges,
      );
      if (widget.checkupData != null && widget.medicines != null) {
        provider.setPendingPrescriptionData(
          checkupData: widget.checkupData!,
          medicines: widget.medicines!,
        );
      }
    });
  }

  @override
  void dispose() {
    _payingController.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    FocusScope.of(context).unfocus();

    final pay = context.read<PaymentProvider>();
    final double opening = pay.openingBalance;
    final double current = pay.currentPayment;
    final double paid = pay.amountPayingToday;
    final double remaining = ((opening + current) - paid) < 0 ? 0 : ((opening + current) - paid);

    bool ok = false;
    if (_paymentMode == 'cash') {
      ok = await context.read<PaymentProvider>().confirmCashPayment();
    } else {
      ok = await context.read<PaymentProvider>().confirmPayment(razorpayKey: 'rzp_test_RZEWtaUsNyw9aC');
    }

    if (!mounted) return;
    final now = DateTime.now();
    if (ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Payment Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient: $_patientName'),
              Text('Doctor: ${pay.doctorName}'),
              Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}'),
              const SizedBox(height: 8),
              Text('Opening Balance: ₹${opening.toStringAsFixed(2)}'),
              Text('Current Payment: ₹${current.toStringAsFixed(2)}'),
              Text('Paid Today: ₹${paid.toStringAsFixed(2)}'),
              const Divider(),
              Text('Remaining: ₹${remaining.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      ).then((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.settings.name == '/clinic');
      });
      _payingController.text = '';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    final pay = context.watch<PaymentProvider>();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Patient Payment', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: pay.loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

                final content = SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 1000 : double.infinity),
                      child: Column(
                        children: [
                          // Patient Info Card
                          _sectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Patient Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(height: 12),
                                _rowText('Name', _patientName),
                                _rowText('Date', dateStr),
                                _rowText('Doctor', widget.doctorName),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bill Summary (read-only)
                          _sectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bill Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(height: 8),
                                _rowText('Opening Balance', '₹${pay.openingBalance.toStringAsFixed(2)}'),
                                _rowText('Current Payment', '₹${pay.currentPayment.toStringAsFixed(2)}'),
                                const Divider(height: 20),
                                _rowText('Total Payment', '₹${pay.totalPayment.toStringAsFixed(2)}', isBold: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Payment Entry
                          _sectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pay Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        value: 'cash',
                                        groupValue: _paymentMode,
                                        onChanged: (v) => setState(() => _paymentMode = v ?? 'cash'),
                                        title: const Text('Cash', style: TextStyle(fontSize: 13)),
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        value: 'online',
                                        groupValue: _paymentMode,
                                        onChanged: (v) => setState(() => _paymentMode = v ?? 'online'),
                                        title: const Text('Online', style: TextStyle(fontSize: 13)),
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _payingController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: context.read<PaymentProvider>().setAmountPayingToday,
                                  decoration: InputDecoration(
                                    labelText: 'Amount Paying Today',
                                    prefixIcon: const Icon(Icons.currency_rupee),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _rowText('Remaining Payment', '₹${pay.remainingBalance.toStringAsFixed(2)}', isBold: true),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: pay.amountPayingToday <= 0 ? null : _confirmPayment,
                                    icon: Icon(_paymentMode == 'cash' ? Icons.money : Icons.wifi_tethering),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    label: Text(_paymentMode == 'cash' ? 'Confirm Payment (Cash)' : 'Confirm Payment (Online)'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Optional history
                          _sectionCard(
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _loadHistory(),
                              builder: (context, snap) {
                                final items = snap.data ?? [];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    const SizedBox(height: 8),
                                    if (items.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text('No history found', style: TextStyle(color: Colors.grey[700])),
                                      )
                                    else ...items.reversed.map((e) => _historyTile(e)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                return content;
              },
            ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('payments_$_patientId');
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(raw));
    } catch (_) {
      return [];
    }
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _rowText(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> e) {
    final dateStr = e['date'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(e['date']))
        : '—';
    final opening = (e['openingBalance'] ?? 0).toString();
    final current = (e['currentPayment'] ?? 0).toString();
    final paid = (e['amountPaid'] ?? 0).toString();
    final remaining = (e['remainingBalance'] ?? 0).toString();

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.receipt_long, color: Colors.blue),
        ),
        title: Text('Paid: ₹$paid', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('Opening: ₹$opening  |  Current: ₹$current', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Remaining', style: TextStyle(fontSize: 11, color: Colors.black54)),
            Text('₹$remaining', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
