import 'parse_helpers.dart';

/// The user's feedback on one instruction.
enum FeedbackStatus {
  onTrack('on_track'), // "I understood, I'm on track"
  unclear('unclear'); // "That instruction was unclear"

  const FeedbackStatus(this.value);

  /// The text saved in Firestore.
  final String value;

  /// Reads the saved text back. Unknown text becomes [onTrack].
  static FeedbackStatus fromValue(String value) =>
      values.firstWhere((s) => s.value == value, orElse: () => onTrack);
}

/// Feedback on one navigation instruction.
/// Stored in settings/{uid}/feedback.
class InstructionFeedback {
  final String id; // Firestore document id
  final String instruction;
  final FeedbackStatus status;
  final DateTime? createdAt; // set by the server

  const InstructionFeedback({
    required this.id,
    required this.instruction,
    required this.status,
    this.createdAt,
  });

  factory InstructionFeedback.fromMap(String id, Map<String, dynamic> map) {
    return InstructionFeedback(
      id: id,
      instruction: readString(map, 'instruction', ''),
      status: FeedbackStatus.fromValue(readString(map, 'status', '')),
      createdAt: readDate(map, 'createdAt'),
    );
  }

  /// createdAt is left out: the repository sets it with a server timestamp.
  Map<String, dynamic> toMap() {
    return {'instruction': instruction, 'status': status.value};
  }
}
