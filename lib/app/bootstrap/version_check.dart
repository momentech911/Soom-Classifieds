/// Semantic-version comparison for the force-update check.
///
/// Handles the `1.2.3` / `1.2.3+45` shapes `package_info_plus` returns. The
/// build suffix is ignored: force-update decisions are made on the semantic
/// version, not the build number.
abstract final class VersionCheck {
  /// Compares [a] and [b]: negative if a < b, zero if equal, positive if a > b.
  ///
  /// Missing segments count as zero, so `1.2` equals `1.2.0`. Non-numeric
  /// segments are treated as zero rather than throwing — a malformed version
  /// from the backend must not crash startup.
  static int compare(String a, String b) {
    final List<int> left = _segments(a);
    final List<int> right = _segments(b);
    final int length = left.length > right.length ? left.length : right.length;

    for (int i = 0; i < length; i++) {
      final int l = i < left.length ? left[i] : 0;
      final int r = i < right.length ? right[i] : 0;
      if (l != r) return l < r ? -1 : 1;
    }
    return 0;
  }

  /// Whether [current] is older than [minimumSupported], i.e. must update.
  ///
  /// Returns false when [minimumSupported] is null or blank — the backend not
  /// specifying a floor must never lock users out.
  static bool isUpdateRequired({
    required String current,
    required String? minimumSupported,
  }) {
    if (minimumSupported == null || minimumSupported.trim().isEmpty) {
      return false;
    }
    return compare(current, minimumSupported) < 0;
  }

  static List<int> _segments(String version) {
    // Drop any build suffix: 1.2.3+45 -> 1.2.3
    final String core = version.split('+').first.trim();
    return core
        .split('.')
        .map((String part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
