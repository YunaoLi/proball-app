class ArgumentException extends FormatException {
/// The command that was parsed before discovering the error.
  ///
  /// This will be empty if the error was on the root parser.
  final String? command;    // Command that was parsed before discovering the error.

  /// The name of the argument that was being parsed when the error was
  /// discovered.
  final String? argumentName;

  /// Creates a new [ArgumentException] with the given message, command, and argument name.
  ArgumentException(
    super.message, [
    this.command,
    this.argumentName,
    super.source,
    super.offset,
  ]);


  /// Returns a string representation of the [ArgumentException].
  @override
  String toString() {
    return 'ArgumentException: $message';
  }
}