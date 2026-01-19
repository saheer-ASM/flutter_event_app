import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  bool _isRegistered = false;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _userData = await _firestoreService.getUserData(authService.currentUser!.uid);
    
    if (_userData != null) {
      setState(() {
        _isRegistered = _userData!.registeredEvents.contains(widget.event.id);
        _isLoading = false;
      });
    }
  }

  Future<void> _registerForEvent() async {
    if (_userData == null) return;

    setState(() => _isLoading = true);

    final error = await _firestoreService.registerForEvent(_userData!.uid, widget.event.id);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      setState(() => _isRegistered = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully registered!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _unregisterFromEvent() async {
    if (_userData == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unregister'),
        content: const Text('Are you sure you want to unregister from this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unregister'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final error = await _firestoreService.unregisterFromEvent(_userData!.uid, widget.event.id);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      setState(() => _isRegistered = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unregistered successfully'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Image
            if (widget.event.imageUrl != null)
              Image.network(
                widget.event.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 80),
                  );
                },
              )
            else
              Container(
                height: 250,
                color: Colors.grey.shade300,
                child: const Icon(Icons.event, size: 80),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.event.category,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date & Time
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date',
                    DateFormat('EEEE, MMMM dd, yyyy').format(widget.event.date),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time, 'Time', widget.event.time),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, 'Location', widget.event.location),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.business, 'Organized By', widget.event.organizedBy),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.event_seat,
                    'Seats Available',
                    '${widget.event.seatsAvailable} / ${widget.event.maxCount}',
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register/Unregister Button
                  if (!_isLoading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.event.seatsAvailable <= 0 && !_isRegistered
                            ? null
                            : _isRegistered
                                ? _unregisterFromEvent
                                : _registerForEvent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _isRegistered ? Colors.red : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.event.seatsAvailable <= 0 && !_isRegistered
                              ? 'Event Full'
                              : _isRegistered
                                  ? 'Unregister'
                                  : 'Register Now',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}