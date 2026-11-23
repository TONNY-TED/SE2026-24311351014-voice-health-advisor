# flutter_gallery — doctor profile images

Drop doctor photos here.

For Dr. Vitumbiko, save the file as exactly:

  flutter_gallery/dr.vitumbiko.jpg

The path is configured in `lib/data/doctor_data.dart` (`imageAssetPath`).
If your file is a PNG instead, either rename it to `dr.vitumbiko.jpg`
or update that one line to `flutter_gallery/dr.vitumbiko.png`.

Until the file exists, the app shows a professional placeholder avatar —
it will not crash (see `DoctorCard` errorBuilder).
