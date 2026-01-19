import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../services/firestore_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  List<_NotificationItem> _buildNotifications(List<EventModel> events) {
    final now = DateTime.now();
    final List<_NotificationItem> items = [];

    for (final event in events) {
      // New Event Added: created today
      if (now.difference(event.createdAt).inHours <= 24 && now.isAfter(event.createdAt)) {
        items.add(
          _NotificationItem(
            title: 'New Event Added',
            message: '${event.title} has been added to ${event.category} category.',
            type: NotificationType.newEvent,
            time: event.createdAt,
          ),
        );
      }

      // Event Starting Soon: within next 2 hours
      try {
        final eventDateTime = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );
        final diff = eventDateTime.difference(now).inHours;
        if (diff >= 0 && diff <= 2) {
          items.add(
            _NotificationItem(
              title: 'Event Starting Soon',
              message: '${event.title} starts soon. Don\'t forget to attend!',
              type: NotificationType.startingSoon,
              time: eventDateTime,
            ),
          );
        }
      } catch (_) {}

      // Trending Event: many registrations (based on filled seats)
      final registeredCount = event.maxCount - event.seatsAvailable;
      if (registeredCount >= 20) {
        items.add(
          _NotificationItem(
            title: 'Trending Event',
            message:
                '${event.title} is trending with $registeredCount+ registrations!',
            type: NotificationType.trending,
            time: event.createdAt,
          ),
        );
      }
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: firestoreService.getAllEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          final notifications = _buildNotifications(events);

          if (notifications.isEmpty) {
            return const Center(
              child: Text('No notifications yet'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _NotificationCard(item: item);
            },
          );
        },
      ),
    );
  }
}

enum NotificationType { startingSoon, newEvent, trending }

class _NotificationItem {
  final String title;
  final String message;
  final NotificationType type;
  final DateTime time;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.type,
    required this.time,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationCard({required this.item});

  Color _iconColor() {
    switch (item.type) {
      case NotificationType.startingSoon:
        return Colors.orange;
      case NotificationType.newEvent:
        return Colors.redAccent;
      case NotificationType.trending:
        return Colors.teal;
    }
  }

  IconData _iconData() {
    switch (item.type) {
      case NotificationType.startingSoon:
        return Icons.event;
      case NotificationType.newEvent:
        return Icons.notifications;
      case NotificationType.trending:
        return Icons.star;
    }
  }

  String _timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(item.time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _iconColor().withOpacity(0.9),
                    _iconColor().withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                _iconData(),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
