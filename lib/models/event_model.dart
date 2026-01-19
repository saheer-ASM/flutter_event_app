import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String organizedBy;
  final DateTime date;
  final String time;
  final String location;
  final int maxCount;
  final int seatsAvailable;
  final String? imageUrl;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.organizedBy,
    required this.date,
    required this.time,
    required this.location,
    required this.maxCount,
    required this.seatsAvailable,
    this.imageUrl,
    required this.createdAt,
  });

  // Convert Firestore document to EventModel
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      organizedBy: data['organizedBy'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      maxCount: data['maxCount'] ?? 0,
      seatsAvailable: data['seatsAvailable'] ?? 0,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert EventModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'organizedBy': organizedBy,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'maxCount': maxCount,
      'seatsAvailable': seatsAvailable,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}