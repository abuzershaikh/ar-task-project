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
  /// Example: 'Order Quantity (Subscribers)' or 'Order Quantity (Likes)'
  static String getQuantityHeader(String? serviceCodeOrName) {
    final plural = getUnitName(serviceCodeOrName, count: 2);
    return 'Order Quantity ($plural)';
  }

  /// Returns dynamic subtitle for service details.
  /// Example: '1 Subscriber = 1 Real Channel Subscriber'
  static String getUnitExplanation(String? serviceCodeOrName) {
    final singular = getUnitName(serviceCodeOrName, count: 1);
    if (singular == 'Subscriber') {
      return '1 Subscriber = 1 Real Channel Subscription';
    } else if (singular == 'Like') {
      return '1 Like = 1 Genuine Video Like';
    } else if (singular == 'Comment') {
      return '1 Comment = 1 Unique Relevant Comment';
    } else if (singular == 'View') {
      return '1 View = 1 Full-Watch Video View';
    } else if (singular == 'Review') {
      return '1 Review = 1 Real Store Rating & Review';
    } else if (singular == 'Install') {
      return '1 Install = 1 Verified App Installation';
    }
    return '1 $singular = 1 Verified Worker Execution';
  }
}
