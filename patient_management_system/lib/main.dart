import 'package:flutter/material.dart';
import 'package:patient_management_system/app/data/providers/auth_provider.dart';
import 'package:patient_management_system/app/data/providers/checkup_provider.dart';
import 'package:patient_management_system/app/data/providers/payment_provider.dart';
import 'package:patient_management_system/app/modules/home/views/splash_page.dart';
import 'package:provider/provider.dart';
import 'app/data/providers/patient_provider.dart';
import 'app/data/providers/clinic_provider.dart';
import 'app/data/providers/medicine_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClinicProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => CheckupProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        title: 'Med Track',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    ); 
  }
}
