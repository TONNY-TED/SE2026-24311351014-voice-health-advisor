// Doctors Screen: consultation destination for the bottom navigation.
// Reuses the existing DoctorSection cards + booking flow unchanged.

import 'package:flutter/material.dart';

import '../widgets/doctor_section.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar matching the app style.
      appBar: AppBar(
        title: const Text('Doctors'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        // Existing profile cards + Book Appointment buttons.
        child: DoctorSection(),
      ),
    );
  }
}
