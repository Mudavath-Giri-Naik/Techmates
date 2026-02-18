/// Returns a human-readable "time ago" string like Instagram.
/// e.g. "Just now", "5 min ago", "2 hours ago", "Yesterday", "3 days ago", "1 month ago"
String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.isNegative) return 'Just now';

  final seconds = diff.inSeconds;
  final minutes = diff.inMinutes;
  final hours = diff.inHours;
  final days = diff.inDays;

  if (seconds < 60) {
    return 'Just now';
  } else if (minutes < 60) {
    return minutes == 1 ? '1 min ago' : '$minutes min ago';
  } else if (hours < 24) {
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  } else if (days == 1) {
    return 'Yesterday';
  } else if (days < 30) {
    return '$days days ago';
  } else if (days < 365) {
    final months = (days / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  } else {
    final years = (days / 365).floor();
    return years == 1 ? '1 year ago' : '$years years ago';
  }
}
