import 'parse_helpers.dart';

/// What a voice command does.
enum CommandAction {
  repeat('repeat'), // say the last instruction again
  next('next'), // read the next instruction
  settings('settings'), // open the settings screen
  stop('stop'); // stop speaking / navigation

  const CommandAction(this.value);

  /// The text saved in Firestore.
  final String value;

  /// Reads the saved text back. Unknown text becomes [repeat].
  static CommandAction fromValue(String value) =>
      values.firstWhere((a) => a.value == value, orElse: () => repeat);
}

/// A phrase the user has chosen for an action, e.g. "say again" -> repeat.
/// Stored in settings/{uid}/custom_commands.
class CustomCommand {
  final String id; // Firestore document id
  final String phrase;
  final CommandAction action;
  final bool enabled;
  final DateTime? createdAt; // set by the server

  const CustomCommand({
    required this.id,
    required this.phrase,
    required this.action,
    this.enabled = true,
    this.createdAt,
  });

  factory CustomCommand.fromMap(String id, Map<String, dynamic> map) {
    return CustomCommand(
      id: id,
      phrase: readString(map, 'phrase', ''),
      action: CommandAction.fromValue(readString(map, 'action', '')),
      enabled: readBool(map, 'enabled', true),
      createdAt: readDate(map, 'createdAt'),
    );
  }

  /// createdAt is left out: the repository sets it with a server timestamp.
  Map<String, dynamic> toMap() {
    return {'phrase': phrase, 'action': action.value, 'enabled': enabled};
  }

  /// Returns a copy with only the given fields changed.
  CustomCommand copyWith({
    String? phrase,
    CommandAction? action,
    bool? enabled,
  }) {
    return CustomCommand(
      id: id,
      phrase: phrase ?? this.phrase,
      action: action ?? this.action,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
    );
  }
}
