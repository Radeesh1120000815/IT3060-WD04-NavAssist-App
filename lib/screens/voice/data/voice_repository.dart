import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'alert_log_entry.dart';
import 'custom_command.dart';
import 'instruction_feedback.dart';
import 'instruction_history_entry.dart';
import 'voice_settings.dart';

/// An error with a simple message that a screen can show or speak.
class VoiceDataException implements Exception {
  const VoiceDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Every Firestore read and write for Member 2 (Voice & Accessibility).
///
/// Data layout (uid = the signed-in user's id):
///   settings/{uid}                      -> VoiceSettings
///   settings/{uid}/instruction_history  -> InstructionHistoryEntry
///   settings/{uid}/custom_commands      -> CustomCommand
///   settings/{uid}/alert_log            -> AlertLogEntry
///   settings/{uid}/feedback             -> InstructionFeedback
///
/// Every failure is turned into a [VoiceDataException], so callers only
/// need to catch one error type.
class VoiceRepository {
  VoiceRepository({this.firestore, this.auth});

  /// Optional: only passed in tests. Normally left null.
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  // Firebase is only used when first needed, so tests can create this
  // class without starting Firebase.
  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authInstance => auth ?? FirebaseAuth.instance;

  // How long to wait for the server before giving up.
  static const Duration _timeout = Duration(seconds: 10);

  // Firestore collection names.
  static const String settingsCollection = 'settings';
  static const String historyCollection = 'instruction_history';
  static const String commandsCollection = 'custom_commands';
  static const String alertLogCollection = 'alert_log';
  static const String feedbackCollection = 'feedback';

  // A Firestore batch can hold at most 500 writes.
  static const int _maxBatchSize = 500;

  // ---------------------------------------------------------------------
  // User id and error handling helpers
  // ---------------------------------------------------------------------

  /// Returns the current user id.
  /// If nobody is signed in, signs in anonymously first.
  Future<String> currentUserId() async {
    try {
      final user =
          _authInstance.currentUser ??
          (await _authInstance.signInAnonymously().timeout(_timeout)).user;
      if (user == null) {
        throw const VoiceDataException('Could not sign in. Please try again.');
      }
      return user.uid;
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  // settings/{uid}
  Future<DocumentReference<Map<String, dynamic>>> _settingsRef() async {
    final uid = await currentUserId();
    return _db.collection(settingsCollection).doc(uid);
  }

  // settings/{uid}/{name}
  Future<CollectionReference<Map<String, dynamic>>> _subCollection(
    String name,
  ) async {
    final settingsRef = await _settingsRef();
    return settingsRef.collection(name);
  }

  // Runs a read. Any failure becomes a VoiceDataException.
  Future<T> _read<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  // Runs a write. With no internet, Firestore keeps the write on the phone
  // and sends it later, but the Future only finishes when the server replies.
  // So a timeout here means "saved on the phone, will sync later", not failure.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action().timeout(_timeout);
    } on TimeoutException {
      debugPrint('VoiceRepository: offline, write queued until online.');
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  // Adds a stream error handler that turns errors into VoiceDataException.
  StreamTransformer<T, T> _friendlyErrors<T>() {
    return StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        sink.addError(_friendlyError(error), stackTrace);
      },
    );
  }

  // Turns any error into a short message a user can understand.
  VoiceDataException _friendlyError(Object error) {
    if (error is VoiceDataException) return error;
    debugPrint('VoiceRepository error: $error');

    if (error is TimeoutException) {
      return const VoiceDataException(
        'The server took too long to reply. Check your internet connection.',
      );
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'network-request-failed':
          return const VoiceDataException(
            'No internet connection. Please try again later.',
          );
        case 'permission-denied':
          return const VoiceDataException(
            'You do not have permission to access this data.',
          );
        case 'not-found':
          return const VoiceDataException('That item no longer exists.');
      }
    }
    return const VoiceDataException('Something went wrong. Please try again.');
  }

  // ---------------------------------------------------------------------
  // Shared helpers for the four sub-collections
  // ---------------------------------------------------------------------

  // CREATE: adds a document and returns its id.
  // The id is made on the phone, so this also works offline.
  Future<String> _add(String collection, Map<String, dynamic> data) async {
    final col = await _subCollection(collection);
    final ref = col.doc();
    await _write(() => ref.set(data));
    return ref.id;
  }

  // READ (live): the collection as a list that updates by itself.
  Stream<List<T>> _watch<T>(
    String collection,
    String orderByField,
    T Function(String id, Map<String, dynamic> data) fromMap, {
    bool newestFirst = true,
    int? limit,
  }) async* {
    final col = await _subCollection(collection);
    Query<Map<String, dynamic>> query = col.orderBy(
      orderByField,
      descending: newestFirst,
    );
    if (limit != null) query = query.limit(limit);

    yield* query
        .snapshots()
        .map((snap) => snap.docs.map((d) => fromMap(d.id, d.data())).toList())
        .transform(_friendlyErrors());
  }

  // UPDATE: changes some fields of one document.
  Future<void> _update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final col = await _subCollection(collection);
    await _write(() => col.doc(id).update(data));
  }

  // DELETE: removes one document.
  Future<void> _delete(String collection, String id) async {
    final col = await _subCollection(collection);
    await _write(() => col.doc(id).delete());
  }

  // DELETE: removes every document in the collection, in batches.
  Future<void> _clear(String collection) async {
    final col = await _subCollection(collection);
    final snapshot = await _read(() => col.get());
    final docs = snapshot.docs;

    for (var start = 0; start < docs.length; start += _maxBatchSize) {
      final batch = _db.batch();
      for (final doc in docs.skip(start).take(_maxBatchSize)) {
        batch.delete(doc.reference);
      }
      await _write(batch.commit);
    }
  }

  // ---------------------------------------------------------------------
  // Settings document: settings/{uid}
  // ---------------------------------------------------------------------

  // The default settings plus both timestamps, ready to save.
  Map<String, dynamic> _defaultSettingsData() {
    return {
      ...const VoiceSettings().toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// CREATE: saves the default settings for the current user.
  Future<VoiceSettings> createDefaultSettings() async {
    final ref = await _settingsRef();
    await _write(() => ref.set(_defaultSettingsData()));
    return const VoiceSettings();
  }

  /// READ (once): returns the user's settings.
  /// If the document does not exist yet, the defaults are created first.
  Future<VoiceSettings> getSettings() async {
    final ref = await _settingsRef();
    final snapshot = await _read(() => ref.get());
    final data = snapshot.data();
    if (data == null) return createDefaultSettings();
    return VoiceSettings.fromMap(data);
  }

  /// READ (live): settings that update by themselves when they change.
  /// A missing document gives the default settings.
  Stream<VoiceSettings> watchSettings() async* {
    final ref = await _settingsRef();
    yield* ref
        .snapshots()
        .map((snap) {
          final data = snap.data();
          return data == null
              ? const VoiceSettings()
              : VoiceSettings.fromMap(data);
        })
        .transform(_friendlyErrors());
  }

  /// UPDATE: saves new settings and the time of the change.
  /// "merge" means it also works if the document is missing.
  Future<void> updateSettings(VoiceSettings settings) async {
    final ref = await _settingsRef();
    await _write(
      () => ref.set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  /// DELETE + CREATE: deletes settings/{uid}, then writes the defaults again.
  /// Both steps are in one batch, so they happen together or not at all.
  /// Note: Firestore does not delete sub-collections with their parent,
  /// so history, commands, alerts and feedback are kept.
  Future<VoiceSettings> resetToDefault() async {
    final ref = await _settingsRef();
    final batch = _db.batch()
      ..delete(ref)
      ..set(ref, _defaultSettingsData());
    await _write(batch.commit);
    return const VoiceSettings();
  }

  // ---------------------------------------------------------------------
  // Instruction history: settings/{uid}/instruction_history
  // ---------------------------------------------------------------------

  /// CREATE: records an instruction that was just spoken.
  Future<String> addInstructionHistory(String text) {
    return _add(historyCollection, {
      ...InstructionHistoryEntry(id: '', text: text).toMap(),
      'spokenAt': FieldValue.serverTimestamp(),
    });
  }

  /// READ (live): the most recent spoken instructions, newest first.
  Stream<List<InstructionHistoryEntry>> watchInstructionHistory({
    int limit = 20,
  }) {
    return _watch(
      historyCollection,
      'spokenAt',
      InstructionHistoryEntry.fromMap,
      limit: limit,
    );
  }

  /// DELETE: removes the whole instruction history.
  Future<void> clearInstructionHistory() => _clear(historyCollection);

  // ---------------------------------------------------------------------
  // Custom voice commands: settings/{uid}/custom_commands
  // ---------------------------------------------------------------------

  /// CREATE: adds a new command phrase, e.g. "say again" -> repeat.
  Future<String> addCustomCommand(
    String phrase,
    CommandAction action, {
    bool enabled = true,
  }) async {
    final cleanPhrase = phrase.trim().toLowerCase();
    if (cleanPhrase.isEmpty) {
      throw const VoiceDataException('Please enter a phrase for the command.');
    }
    final command = CustomCommand(
      id: '',
      phrase: cleanPhrase,
      action: action,
      enabled: enabled,
    );
    return _add(commandsCollection, {
      ...command.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// READ (once): all custom commands, oldest first.
  /// Used by the voice command parser.
  Future<List<CustomCommand>> getCustomCommands() async {
    final col = await _subCollection(commandsCollection);
    final snapshot = await _read(() => col.orderBy('createdAt').get());
    return snapshot.docs
        .map((d) => CustomCommand.fromMap(d.id, d.data()))
        .toList();
  }

  /// READ (live): all custom commands, oldest first.
  Stream<List<CustomCommand>> watchCustomCommands() {
    return _watch(
      commandsCollection,
      'createdAt',
      CustomCommand.fromMap,
      newestFirst: false,
    );
  }

  /// UPDATE: saves a changed phrase, action or enabled switch.
  Future<void> updateCustomCommand(CustomCommand command) async {
    final cleanPhrase = command.phrase.trim().toLowerCase();
    if (cleanPhrase.isEmpty) {
      throw const VoiceDataException('Please enter a phrase for the command.');
    }
    return _update(
      commandsCollection,
      command.id,
      command.copyWith(phrase: cleanPhrase).toMap(),
    );
  }

  /// DELETE: removes one custom command.
  Future<void> deleteCustomCommand(String id) =>
      _delete(commandsCollection, id);

  // ---------------------------------------------------------------------
  // Alert log: settings/{uid}/alert_log
  // ---------------------------------------------------------------------

  /// CREATE: records an alert that was just shown (UR-02).
  Future<String> logAlert({
    required String type,
    required AlertSeverity severity,
    required String message,
  }) {
    final entry = AlertLogEntry(
      id: '',
      type: type,
      severity: severity,
      message: message,
    );
    return _add(alertLogCollection, {
      ...entry.toMap(),
      'firedAt': FieldValue.serverTimestamp(),
    });
  }

  /// READ (live): all alerts, newest first.
  Stream<List<AlertLogEntry>> watchAlertLog() {
    return _watch(alertLogCollection, 'firedAt', AlertLogEntry.fromMap);
  }

  /// UPDATE: marks an alert as dismissed by the user.
  Future<void> acknowledgeAlert(String id) {
    return _update(alertLogCollection, id, {'acknowledged': true});
  }

  /// DELETE: removes the whole alert log.
  Future<void> clearAlertLog() => _clear(alertLogCollection);

  // ---------------------------------------------------------------------
  // Instruction feedback: settings/{uid}/feedback
  // ---------------------------------------------------------------------

  /// CREATE: saves the user's feedback on one instruction.
  Future<String> addFeedback(String instruction, FeedbackStatus status) {
    final feedback = InstructionFeedback(
      id: '',
      instruction: instruction,
      status: status,
    );
    return _add(feedbackCollection, {
      ...feedback.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// READ (live): all feedback, newest first.
  Stream<List<InstructionFeedback>> watchFeedback() {
    return _watch(feedbackCollection, 'createdAt', InstructionFeedback.fromMap);
  }

  /// UPDATE: changes the status of earlier feedback.
  Future<void> updateFeedback(String id, FeedbackStatus status) {
    return _update(feedbackCollection, id, {'status': status.value});
  }

  /// DELETE: removes one feedback entry.
  Future<void> deleteFeedback(String id) => _delete(feedbackCollection, id);
}
