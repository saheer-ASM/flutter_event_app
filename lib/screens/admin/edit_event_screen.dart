import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/image_service.dart';
import '../../models/event_model.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _organizedByController;
  late TextEditingController _locationController;
  late TextEditingController _maxCountController;
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  File? _imageFile;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final ImageService _imageService = ImageService();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'Technical',
    'Cultural',
    'Sports',
    'Workshop',
    'Seminar',
    'Competition',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _categoryController = TextEditingController(text: widget.event.category);
    _organizedByController = TextEditingController(text: widget.event.organizedBy);
    _locationController = TextEditingController(text: widget.event.location);
    _maxCountController = TextEditingController(text: widget.event.maxCount.toString());
    _selectedDate = widget.event.date;
    
    // Parse time from string
    final timeParts = widget.event.time.split(':');
    int hour = int.parse(timeParts[0].trim().split(' ')[0]);
    final minute = int.parse(timeParts[1].trim().split(' ')[0]);
    final isPM = widget.event.time.toLowerCase().contains('pm');
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    _selectedTime = TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _organizedByController.dispose();
    _locationController.dispose();
    _maxCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.event.imageUrl;

      // Upload new image if selected
      if (_imageFile != null) {
        // Delete old image if exists


        imageUrl = await _imageService.uploadEventImage(_imageFile!);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Calculate seats available based on max count change
      final int maxCountDiff = int.parse(_maxCountController.text) - widget.event.maxCount;
      final int newSeatsAvailable = widget.event.seatsAvailable + maxCountDiff;

      // Update event
      final updatedEvent = EventModel(
        id: widget.event.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        organizedBy: _organizedByController.text.trim(),
        date: _selectedDate,
        time: _selectedTime.format(context),
        location: _locationController.text.trim(),
        maxCount: int.parse(_maxCountController.text.trim()),
        seatsAvailable: newSeatsAvailable >= 0 ? newSeatsAvailable : 0,
        imageUrl: imageUrl,
        createdAt: widget.event.createdAt,
      );

      await _firestoreService.updateEvent(widget.event.id, updatedEvent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : widget.event.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(widget.event.imageUrl!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 60, color: Colors.grey.shade600),
                                const SizedBox(height: 8),
                                Text('Tap to change image', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  prefixIcon: const Icon(Icons.event),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _categoryController.text,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  if (value != null) _categoryController.text = value;
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _organizedByController,
                decoration: InputDecoration(
                  labelText: 'Organized By *',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text('Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text('Time: ${_selectedTime.format(context)}'),
                leading: const Icon(Icons.access_time),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                onTap: _selectTime,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _maxCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Registrations *',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Enter valid number';
                  if (int.parse(value) <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _updateEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update Event', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}