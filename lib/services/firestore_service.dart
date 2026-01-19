import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== USER OPERATIONS ==========

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user name
  Future<void> updateUserName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({'name': name});
  }

  // Update user profile image
  Future<void> updateUserProfileImage(String uid, String imageUrl) async {
    await _firestore.collection('users').doc(uid).update({'profileImageUrl': imageUrl});
  }

  // ========== EVENT OPERATIONS ==========

  // Get all events (stream)
  Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Get upcoming events only
  Stream<List<EventModel>> getUpcomingEvents() {
    DateTime now = DateTime.now();
    return _firestore
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Get registered events for a user
  Stream<List<EventModel>> getRegisteredEvents(List<String> eventIds) {
    if (eventIds.isEmpty) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('events')
        .where(FieldPath.documentId, whereIn: eventIds)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Create event
  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').add(event.toMap());
  }

  // Update event
  Future<void> updateEvent(String eventId, EventModel event) async {
    await _firestore.collection('events').doc(eventId).update(event.toMap());
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  // Register user for event
  Future<String?> registerForEvent(String uid, String eventId) async {
    try {
      // Get event document
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      
      if (!eventDoc.exists) {
        return 'Event not found';
      }

      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      int seatsAvailable = eventData['seatsAvailable'] ?? 0;

      if (seatsAvailable <= 0) {
        return 'No seats available';
      }

      // Update user's registered events
      await _firestore.collection('users').doc(uid).update({
        'registeredEvents': FieldValue.arrayUnion([eventId])
      });

      // Decrease seats available
      await _firestore.collection('events').doc(eventId).update({
        'seatsAvailable': seatsAvailable - 1
      });

      return null; // Success
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  // Unregister user from event
  Future<String?> unregisterFromEvent(String uid, String eventId) async {
    try {
      // Get event document
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      
      if (!eventDoc.exists) {
        return 'Event not found';
      }

      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      int seatsAvailable = eventData['seatsAvailable'] ?? 0;

      // Update user's registered events
      await _firestore.collection('users').doc(uid).update({
        'registeredEvents': FieldValue.arrayRemove([eventId])
      });

      // Increase seats available
      await _firestore.collection('events').doc(eventId).update({
        'seatsAvailable': seatsAvailable + 1
      });

      return null; // Success
    } catch (e) {
      return 'Unregistration failed: $e';
    }
  }

  // Search events by title or category
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .get();

      List<EventModel> allEvents = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Filter by title or category
      return allEvents.where((event) {
        return event.title.toLowerCase().contains(query.toLowerCase()) ||
               event.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }
}