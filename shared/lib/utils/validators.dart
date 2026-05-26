class Validators {
  Validators._();

  /// Returns true if [slot] is at least 1 minute in the future.
  static bool isValidFutureSlot(DateTime slot) =>
      slot.isAfter(DateTime.now().add(const Duration(minutes: 1)));

  /// Returns an error string or null if valid.
  static String? validateNote(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > 140) return 'Note must be 140 characters or less';
    return null;
  }

  /// Returns true if [name] is non-empty after trimming.
  static bool isValidName(String name) => name.trim().isNotEmpty;
}
