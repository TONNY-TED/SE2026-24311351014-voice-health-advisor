// Doctor Consultation section: profile cards + Book Appointment entry.
// Placed near the bottom of HomeScreen. Matches the reference UI design
// with large doctor image at top, name below, then details.

import 'package:material_ui/material_ui.dart';

import '../data/doctor_data.dart';
import '../screens/book_appointment_screen.dart';

class DoctorSection extends StatelessWidget {
  const DoctorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doctor Consultation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Browse doctors and book an appointment.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        for (final doctor in kDoctors) DoctorCard(doctor: doctor),
      ],
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final hasBio = doctor.description.trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor profile image - large, full width at top.
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: doctor.imageAssetPath.isNotEmpty
                ? Image.asset(
                    doctor.imageAssetPath,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
          ),

          // Doctor details below image.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor name.
                Text(
                  doctor.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Doctor title / specialty.
                Text(
                  'General Medical Doctor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 12),

                // Contact info row.
                if (doctor.email.trim().isNotEmpty ||
                    doctor.phone.trim().isNotEmpty)
                  Row(
                    children: [
                      if (doctor.email.trim().isNotEmpty)
                        const Icon(Icons.email_outlined,
                            size: 16, color: Colors.grey),
                      if (doctor.email.trim().isNotEmpty &&
                          doctor.phone.trim().isNotEmpty)
                        const SizedBox(width: 8),
                      if (doctor.email.trim().isNotEmpty)
                        Expanded(
                          child: Text(
                            doctor.email.trim(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (doctor.email.trim().isNotEmpty &&
                          doctor.phone.trim().isNotEmpty)
                        const SizedBox(width: 12),
                      if (doctor.phone.trim().isNotEmpty)
                        const Icon(Icons.phone_outlined,
                            size: 16, color: Colors.grey),
                      if (doctor.phone.trim().isNotEmpty)
                        const SizedBox(width: 8),
                      if (doctor.phone.trim().isNotEmpty)
                        Expanded(
                          child: Text(
                            doctor.phone.trim(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Bio / description.
                if (hasBio)
                  Text(
                    doctor.description.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),

                const SizedBox(height: 16),

                // Book Appointment button.
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookAppointmentScreen(doctor: doctor),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
