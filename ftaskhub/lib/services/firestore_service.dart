import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // AUTH HELPER
  // =========================
  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  // =========================
  // USERS
  // =========================

  Future<void> upsertMyUserProfile() async {
    final u = _auth.currentUser;
    if (u == null) return;

    final email = (u.email ?? '').trim();
    final emailLower = email.toLowerCase();

    await _db.collection('users').doc(u.uid).set({
      'uid': u.uid,
      'name': u.displayName ?? '',
      'email': email,
      'emailLower': emailLower,
      'photoUrl': u.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> findUsersByEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return [];

    final snap = await _db
        .collection('users')
        .where('emailLower', isEqualTo: e)
        .limit(10)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // =========================
  // GROUPS
  // =========================

  Future<void> createGroup({
    required String name,
    required String description,
    required List<String> memberIds,
  }) async {
    final creatorId = _uid;

    final members = <String>{
      creatorId,
      ...memberIds.where((e) => e.trim().isNotEmpty),
    }.toList();

    final doc = _db.collection('groups').doc();

    await doc.set({
      'name': name.trim(),
      'description': description.trim(),
      'creatorId': creatorId,
      'adminIds': [creatorId],
      'memberIds': members,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 notif ke member lain
    for (final uid in members) {
      if (uid == creatorId) continue;
      await _createUserNotification(
        userId: uid,
        type: NotificationType.groupCreated,
        title: 'Group baru',
        message: 'Kamu ditambahkan ke group "$name"',
        groupId: doc.id,
      );
    }
  }

  Stream<List<Map<String, dynamic>>> streamMyGroups() {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<Map<String, dynamic>?> getGroupById(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...(doc.data() ?? {})};
  }

  Stream<Map<String, dynamic>?> streamGroupById(String groupId) {
    return _db.collection('groups').doc(groupId).snapshots().map((d) {
      if (!d.exists) return null;
      return {'id': d.id, ...(d.data() ?? {})};
    });
  }

  // =========================
  // TASKS
  // =========================

  Stream<List<Map<String, dynamic>>> streamMyAssignedTasks({
    bool ordered = true,
  }) async* {
    if (!ordered) {
      yield* _db
          .collection('tasks')
          .where('assigneeId', isEqualTo: _uid)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
      return;
    }

    try {
      yield* _db
          .collection('tasks')
          .where('assigneeId', isEqualTo: _uid)
          .orderBy('deadline')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        yield* _db
            .collection('tasks')
            .where('assigneeId', isEqualTo: _uid)
            .snapshots()
            .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
      } else {
        rethrow;
      }
    }
  }

  Stream<List<Map<String, dynamic>>> streamTasksByGroup(
    String groupId, {
    bool ordered = true,
  }) async* {
    if (!ordered) {
      yield* _db
          .collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
      return;
    }

    try {
      yield* _db
          .collection('tasks')
          .where('groupId', isEqualTo: groupId)
          .orderBy('deadline')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        yield* _db
            .collection('tasks')
            .where('groupId', isEqualTo: groupId)
            .snapshots()
            .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
      } else {
        rethrow;
      }
    }
  }

  Future<String> createTask({
    required String groupId,
    required String title,
    required String description,
    required String assigneeId,
    required DateTime deadline,
  }) async {
    final createdBy = _uid;

    final doc = await _db.collection('tasks').add({
      'groupId': groupId,
      'title': title.trim(),
      'description': description.trim(),
      'assigneeId': assigneeId,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'deadline': Timestamp.fromDate(deadline),
      'progress': 0,
      'status': 'todo',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 notif untuk assignee (kalau bukan dirinya sendiri)
    if (assigneeId != createdBy) {
      await _createUserNotification(
        userId: assigneeId,
        type: NotificationType.taskAssignment,
        title: 'Tugas baru',
        message: 'Kamu mendapat task "$title"',
        groupId: groupId,
        taskId: doc.id,
      );
    }

    return doc.id;
  }

  Future<void> updateTask({
    required String taskId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('tasks').doc(taskId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 notif task diupdate (ambil data task terbaru)
    final snap = await _db.collection('tasks').doc(taskId).get();
    if (!snap.exists) return;

    final t = snap.data()!;
    final assigneeId = (t['assigneeId'] ?? '').toString();
    final title = (t['title'] ?? 'Task').toString();

    if (assigneeId.isNotEmpty) {
      await _createUserNotification(
        userId: assigneeId,
        type: NotificationType.taskUpdate,
        title: 'Task diupdate',
        message: 'Task "$title" diperbarui',
        taskId: taskId,
        groupId: (t['groupId'] ?? '').toString(),
      );
    }
  }

  Future<void> markTaskDone(String taskId) async {
    await updateTask(taskId: taskId, data: {'status': 'done', 'progress': 100});
  }

  // =========================
  // CHAT
  // =========================

  Stream<List<Map<String, dynamic>>> streamGroupMessages(
    String groupId, {
    int limit = 100,
  }) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
    String? senderName,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return;

    final msg = text.trim();
    if (msg.isEmpty) return;

    await _db.collection('groups').doc(groupId).collection('messages').add({
      'senderId': u.uid,
      'senderName': (senderName ?? u.displayName ?? u.email ?? 'User').trim(),
      'text': msg,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // 🔔 NOTIFICATIONS
  // =========================

  Stream<List<Map<String, dynamic>>> streamMyNotifications({int limit = 50}) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<int> streamUnreadNotificationCount() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markNotificationAsRead(String id) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead() async {
    final ref = _db.collection('users').doc(_uid).collection('notifications');
    final snap = await ref.where('isRead', isEqualTo: false).get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // =========================
  // 🔔 INTERNAL NOTIF CREATOR
  // =========================

  Future<void> _createUserNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? groupId,
    String? taskId,
  }) async {
    await _db.collection('users').doc(userId).collection('notifications').add({
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (groupId != null) 'groupId': groupId,
      if (taskId != null) 'taskId': taskId,
    });
  }
}
