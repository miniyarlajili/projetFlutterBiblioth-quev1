import '../models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final db = FirebaseFirestore.instance;

  Future<void> addEvent(EventModel event) async {
    await db.collection('events').add(event.toMap());
  }

  Future<void> deleteEvent(String id) async {
    await db.collection('events').doc(id).delete();
  }

  Stream<List<EventModel>> getEvents() {
    return db
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}