/// Centralized helper to convert technical service types/codes into clean,
/// human-friendly generic unit names (e.g. Subscribers, Likes, Comments, Views, Reviews)
class ServiceUnitHelper {
  /// Returns contextual unit name for a given service.
  /// Example: getUnitName('youtube_subscribe', count: 50) -> 'Subscribers'
  /// Example: getUnitName('youtube_subscribe', count: 1) -> 'Subscriber'
  static String getUnitName(
    String? serviceCodeOrName, {
    int count = 1,
    bool includeCount = false,
  }) {
    final s = (serviceCodeOrName ?? '').toLowerCase();
    String singular = 'Task';
    String plural = 'Tasks';

    if (s.contains('sub') || s.contains('subscriber')) {
      singular = 'Subscriber';
      plural = 'Subscribers';
    } else if (s.contains('like')) {
      singular = 'Like';
      plural = 'Likes';
    } else if (s.contains('comment')) {
      singular = 'Comment';
      plural = 'Comments';
    } else if (s.contains('watch') || s.contains('view')) {
      singular = 'View';
      plural = 'Views';
    } else if (s.contains('follow')) {
      singular = 'Follower';
      plural = 'Followers';
    } else if (s.contains('install') || s.contains('download')) {
      singular = 'Install';
      plural = 'Installs';
    } else if (s.contains('review') || s.contains('rating')) {
      singular = 'Review';
      plural = 'Reviews';
    } else if (s.contains('share') || s.contains('repost')) {
      singular = 'Share';
      plural = 'Shares';
    } else if (s.contains('combo') || s.contains('engagement')) {
      singular = 'Engagement';
      plural = 'Engagements';
    }

    final name = count == 1 ? singular : plural;
    return includeCount ? '$count $name' : name;
  }

  /// Returns rate display per single unit.
  /// Example: '₹2.00 / subscriber' or '₹1.50 / like'
  static String getRateLabel(String? serviceCodeOrName, double rate) {
    final singular = getUnitName(serviceCodeOrName, count: 1);
    return '₹${rate.toStringAsFixed(2)} / ${singular.toLowerCase()}';
  }

  /// Returns header title for order quantity selector.
  static String getQuantityHeader(String? serviceCodeOrName) {
    final plural = getUnitName(serviceCodeOrName, count: 2);
    return 'Quantity ($plural)';
  }
}
