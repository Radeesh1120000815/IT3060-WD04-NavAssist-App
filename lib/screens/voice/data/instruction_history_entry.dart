import 'parse_helpers.dart';

/// One spoken navigation instruction, e.g. "Turn left onto King Street".
/// Stored in settings/{uid}/instruction_history.
class InstructionHistoryEntry {
  final String id; // Firestore document id
  final String text;
  final DateTime? spokenAt; // set by the server

  const InstructionHistoryEntry({
    required this.id,
    required this.text,
    this.spokenAt,
  });

  factory InstructionHistoryEntry.fromMap(String id, Map<String, dynamic> map) {
    return InstructionHistoryEntry(
      id: id,
      text: readString(map, 'text', ''),
      spokenAt: readDate(map, 'spokenAt'),
    );
  }

  /// spokenAt is left out: the repository sets it with a server timestamp.
  Map<String, dynamic> toMap() => {'text': text};
}
