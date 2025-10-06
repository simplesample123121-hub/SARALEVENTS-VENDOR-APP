import 'package:intl/intl.dart';

class TimeUtils {
  static String formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return iso;
    }
    final df = DateFormat('d MMM yyyy, h:mm a');
    return df.format(dt);
  }

  static String relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    final df = DateFormat('d MMM yyyy');
    return df.format(dt);
  }
}


