// Booking Screen: doctor image at top, calendar date grid, time chips,
// blue Book Appointment button — matches the reference UI design.
// Nothing is sent automatically — user confirms in the external app.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/doctor_data.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  String? _status;
  bool _busy = false;

  // Available time slots (9 AM – 5 PM, every hour).
  final List<TimeOfDay> _timeSlots = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String get _dateLabel {
    if (_date == null) return 'Select date';
    final d = _date!;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String get _timeLabel {
    if (_time == null) return 'Select time';
    final t = _time!;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  bool get _ready =>
      _date != null &&
      _time != null &&
      _nameController.text.trim().isNotEmpty &&
      _contactController.text.trim().isNotEmpty;

  void _selectTime(TimeOfDay time) {
    setState(() => _time = time);
  }

  String _message() {
    final doc = widget.doctor;
    return 'Hello ${doc.displayName},\n\n'
        'I would like to request an appointment through VoiceHealth Care.\n\n'
        'Doctor: ${doc.displayName}\n'
        'Date: $_dateLabel\n'
        'Time: $_timeLabel\n'
        'Patient: ${_nameController.text.trim()}\n'
        'Contact: ${_contactController.text.trim()}\n'
        'Reason: ${_reasonController.text.trim().isEmpty ? '-' : _reasonController.text.trim()}\n\n'
        'Thank you.';
  }

  String _whatsAppPhone() {
    final digits = widget.doctor.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty || digits.startsWith('0')) return '';
    return digits;
  }

  bool _validate() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _status = 'Please complete the highlighted fields.');
      return false;
    }
    if (_date == null || _time == null) {
      setState(() => _status = 'Please select a date and time.');
      return false;
    }
    return true;
  }

  Future<void> _sendEmail() async {
    if (!_validate()) return;
    final email = widget.doctor.email.trim();
    if (email.isEmpty) {
      setState(() => _status = 'This doctor has no email configured yet.');
      return;
    }
    setState(() => _busy = true);
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Doctor Appointment Request — VoiceHealth Care',
        'body': _message(),
      },
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = ok
            ? 'Email app opened — please press Send there to complete the request.'
            : 'Could not open an email app on this device.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Could not open email app: $e';
      });
    }
  }

  Future<void> _sendWhatsApp() async {
    if (!_validate()) return;
    final phone = _whatsAppPhone();
    if (phone.isEmpty) {
      setState(() => _status =
          'This doctor has no valid WhatsApp number yet (needs full international format, e.g. 2659XXXXXXXX).');
      return;
    }
    setState(() => _busy = true);
    final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(_message())}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = ok
            ? 'WhatsApp opened — please press Send there to complete the request.'
            : 'Could not open WhatsApp on this device.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Could not open WhatsApp: $e';
      });
    }
  }

  Widget _buildDoctorHeader() {
    return Column(
      children: [
        // Doctor profile image at top.
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: widget.doctor.imageAssetPath.isNotEmpty &&
                  File(widget.doctor.imageAssetPath).existsSync()
              ? Image.file(
                  File(widget.doctor.imageAssetPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                )
              : const Icon(
                  Icons.person,
                  size: 64,
                  color: Colors.blue,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.doctor.displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Medical Doctor',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (widget.doctor.email.trim().isNotEmpty ||
            widget.doctor.phone.trim().isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.doctor.email.trim().isNotEmpty)
                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
              if (widget.doctor.email.trim().isNotEmpty &&
                  widget.doctor.phone.trim().isNotEmpty)
                const SizedBox(width: 4),
              if (widget.doctor.email.trim().isNotEmpty)
                Text(
                  widget.doctor.email.trim(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (widget.doctor.email.trim().isNotEmpty &&
                  widget.doctor.phone.trim().isNotEmpty)
                const SizedBox(width: 12),
              if (widget.doctor.phone.trim().isNotEmpty)
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
              if (widget.doctor.phone.trim().isNotEmpty)
                const SizedBox(width: 4),
              if (widget.doctor.phone.trim().isNotEmpty)
                Text(
                  widget.doctor.phone.trim(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            itemBuilder: (context, index) {
              final day = DateTime.now().add(Duration(days: index));
              final isSelected =
                  _date != null &&
                  _date!.year == day.year &&
                  _date!.month == day.month &&
                  _date!.day == day.day;
              final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  [day.weekday - 1];
              return GestureDetector(
                onTap: () => setState(() => _date = day),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in _timeSlots)
              ChoiceChip(
                label: Text(
                  '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _time != null &&
                            _time!.hour == slot.hour &&
                            _time!.minute == slot.minute
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                selected: _time != null &&
                    _time!.hour == slot.hour &&
                    _time!.minute == slot.minute,
                onSelected: (_) => _selectTime(slot),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _time != null &&
                            _time!.hour == slot.hour &&
                            _time!.minute == slot.minute
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor profile header with image.
              _buildDoctorHeader(),
              const SizedBox(height: 24),

              // Date selector.
              _buildDateSelector(),
              const SizedBox(height: 20),

              // Time selector.
              _buildTimeSelector(),
              const SizedBox(height: 24),

              // Patient details.
              const Text(
                'Your Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your name.'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Your phone or email',
                  prefixIcon: Icon(Icons.contact_phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your phone or email.'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Brief reason for the visit',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Blue Book Appointment button.
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _busy || !_ready ? null : _sendEmail,
                  icon: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.calendar_today, size: 20),
                  label: Text(
                    _busy
                        ? 'Booking...'
                        : _ready
                            ? 'Book Appointment'
                            : 'Complete all fields',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Alternative: WhatsApp send option.
              if (_whatsAppPhone().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _busy || !_ready ? null : _sendWhatsApp,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Or send via WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Status message.
              if (_status != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _status!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Note.
              const Text(
                'Note: this opens your email or WhatsApp with a prefilled message. Nothing is sent until you press Send there.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

