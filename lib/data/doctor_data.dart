// Doctor directory (Step: Doctor Consultation section).
// Add new doctors by appending to kDoctors — no UI changes needed.
// Dr. Vitumbiko's personal details are EDIT-ME placeholders (intentionally blank).

class Doctor {
  // Stable ID, e.g. 'dr-vitumbiko'.
  final String id;

  // Full name shown on the card (EDIT ME for Dr. Vitumbiko).
  final String fullName;

  // Phone in full international format, e.g. '265991234567' (EDIT ME).
  // WhatsApp needs digits only with country code, no '+' or spaces.
  final String phone;

  // Email for appointment requests (EDIT ME).
  final String email;

  // Short professional biography (EDIT ME).
  final String description;

  // Asset path under flutter_gallery/, e.g. 'flutter_gallery/dr.vitumbiko.jpg'.
  // If the file is missing, the card shows a placeholder instead of crashing.
  final String imageAssetPath;

  const Doctor({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.description,
    required this.imageAssetPath,
  });

  // True when contact fields are filled in (controls Email/WhatsApp buttons).
  bool get hasEmail => email.trim().isNotEmpty;
  bool get hasPhone => phone.trim().isNotEmpty;

  // Display name or a neutral label while details are still placeholders.
  String get displayName =>
      fullName.trim().isEmpty ? 'Doctor (profile coming soon)' : fullName;
}

// Registered doctors. To add one: copy the block, set a new id + image file.
const List<Doctor> kDoctors = [
  Doctor(
    id: 'dr-vitumbiko',
    // Full name.
    fullName: 'Dr. Vitumbiko Mtambo',
    // Phone in international format, digits only (Malawi +265).
    // Local number 0888081368 -> '265888081368' for WhatsApp.
    phone: '265888081368',
    // Email for appointment requests.
    email: 'tonnychibambo@gmail.com',
    // Professional description / biography.
    description:
        'Dr. Vitumbiko Mtambo is a medical doctor who studied at Kamuzu University of Health Sciences (KUHeS), formerly known as the College of Medicine, in Malawi. He works as a general medical doctor, providing medical care to patients across a range of health conditions. His medical training has equipped him with the knowledge and skills to assess, diagnose, treat, and manage various illnesses. He is dedicated to serving patients with professionalism, compassion, and a commitment to improving health and well-being. Through his work in general medicine, Dr. Mtambo seeks to contribute to quality healthcare delivery and make a meaningful difference in the lives of the people he serves.',
    // Image file: save the photo as flutter_gallery/dr.vitumbiko.jpg
    // (or update this line to .png to match the uploaded file).
    imageAssetPath: 'flutter_gallery/dr.vitumbiko.jpg',
  ),
];
