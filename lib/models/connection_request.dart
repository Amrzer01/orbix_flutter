import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime timestamp;

  ConnectionRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
  });

  factory ConnectionRequest.fromMap(Map<String, dynamic> data, String documentId) {
    return ConnectionRequest(
      id: documentId,
      senderId: data['sender_id'] ?? '',
      receiverId: data['receiver_id'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
