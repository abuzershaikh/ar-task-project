/// Centralized helper to convert technical service types/codes into clean,
/// human-friendly generic unit names (e.g. Subscribers, Likes, Comments, Views, Reviews, Ratings)
class ServiceUnitHelper {
  /// Returns contextual unit name for a given service.
  /// Example: getUnitName('GOOGLE_BUSINESS_REVIEW', count: 50) -> 'Reviews'
  /// Example: getUnitName('GOOGLE_BUSINESS_RATING', count: 1) -> 'Rating'
  /// Example: getUnitName('youtube_subscribe', count: 50) -> 'Subscribers'
  /// Example: getUnitName('youtube_subscribe', count: 1) -> 'Subscriber'
  static String getUnitName(
    String? serviceCodeOrName, {
    String? serviceCode,
    int count = 1,
    bool includeCount = false,
  }) {
    final combined = '${serviceCode ?? ''} ${serviceCodeOrName ?? ''}'.toLowerCase();
    String singular = 'Task';
    String plural = 'Tasks';

    // 1. Combos & Bundles (check first so multi-action bundles aren't tagged as single action)
    if (combined.contains('combo') || combined.contains('all-in-one') || combined.contains('bundle')) {
      singular = 'Combo';
      plural = 'Combos';
    }
    // 2. Reviews (CRITICAL: MUST check before 'view', because 'review' contains 'view'!)
    else if (combined.contains('review')) {
      singular = 'Review';
      plural = 'Reviews';
    }
    // 3. Ratings (Only star rating, no written review)
    else if (combined.contains('rating') || combined.contains('star_rating') || combined.contains('rate_only')) {
      singular = 'Rating';
      plural = 'Ratings';
    }
    // 4. Comments
    else if (combined.contains('comment')) {
      singular = 'Comment';
      plural = 'Comments';
    }
    // 5. Views / Watch Time (Guard strictly against 'review')
    else if (combined.contains('watch') || (combined.contains('view') && !combined.contains('review'))) {
      singular = 'View';
      plural = 'Views';
    }
    // 6. Subscribers
    else if (combined.contains('sub') || combined.contains('subscriber')) {
      singular = 'Subscriber';
      plural = 'Subscribers';
    }
    // 7. Likes
    else if (combined.contains('like')) {
      singular = 'Like';
      plural = 'Likes';
    }
    // 8. Followers
    else if (combined.contains('follow')) {
      singular = 'Follower';
      plural = 'Followers';
    }
    // 9. Installs
    else if (combined.contains('install') || combined.contains('download')) {
      singular = 'Install';
      plural = 'Installs';
    }
    // 10. Shares / Reposts
    else if (combined.contains('share') || combined.contains('repost')) {
      singular = 'Share';
      plural = 'Shares';
    }
    // 11. Engagements
    else if (combined.contains('engagement')) {
      singular = 'Engagement';
      plural = 'Engagements';
    }

    final name = count == 1 ? singular : plural;
    return includeCount ? '$count $name' : name;
  }

  /// Returns rate display per single unit.
  /// Example: '₹10.00 / review' or '₹5.00 / rating' or '₹2.00 / subscriber'
  static String getRateLabel(String? serviceCodeOrName, double rate, {String? serviceCode}) {
    final singular = getUnitName(serviceCodeOrName, serviceCode: serviceCode, count: 1);
    return '₹${rate.toStringAsFixed(2)} / ${singular.toLowerCase()}';
  }

  /// Returns header title for order quantity selector.
  /// Example: 'Order Quantity (Reviews)' or 'Order Quantity (Ratings)' or 'Order Quantity (Combos)'
  static String getQuantityHeader(String? serviceCodeOrName, {String? serviceCode}) {
    final plural = getUnitName(serviceCodeOrName, serviceCode: serviceCode, count: 2);
    return 'Order Quantity ($plural)';
  }

  /// Returns dynamic subtitle for service details.
  /// Example: '1 Review = 1 Authentic 5-Star Google Maps Rating & Custom Review'
  static String getUnitExplanation(String? serviceCodeOrName, {String? serviceCode}) {
    final combined = '${serviceCode ?? ''} ${serviceCodeOrName ?? ''}'.toLowerCase();
    if (combined.contains('combo') || combined.contains('bundle') || combined.contains('all-in-one')) {
      if (combined.contains('yt') || combined.contains('youtube')) {
        return '1 Combo = Full Watch Time + Like + Subscribe + Comment';
      } else if (combined.contains('insta') || combined.contains('ig')) {
        return '1 Combo = Real Profile Follower + Post/Reel Like';
      }
      return '1 Combo = Complete Multi-Action Engagement Bundle';
    }

    final singular = getUnitName(serviceCodeOrName, serviceCode: serviceCode, count: 1);
    if (singular == 'Subscriber') {
      return '1 Subscriber = 1 Real Channel Subscription';
    } else if (singular == 'Like') {
      return '1 Like = 1 Genuine Video / Post Like';
    } else if (singular == 'Comment') {
      return '1 Comment = 1 Unique Relevant Comment';
    } else if (singular == 'View') {
      return '1 View = 1 Full-Watch Video View';
    } else if (singular == 'Review') {
      if (combined.contains('google') || combined.contains('map') || combined.contains('gmb')) {
        return '1 Review = 1 Authentic 5-Star Google Maps Rating & Custom Review';
      }
      return '1 Review = 1 Authentic 5-Star Rating & Store Review';
    } else if (singular == 'Rating') {
      if (combined.contains('google') || combined.contains('map') || combined.contains('gmb')) {
        return '1 Rating = 1 Authentic 5-Star Google Maps Rating';
      }
      return '1 Rating = 1 Authentic 5-Star Rating';
    } else if (singular == 'Install') {
      return '1 Install = 1 Verified App Installation';
    } else if (singular == 'Follower') {
      return '1 Follower = 1 Real Profile Follow';
    } else if (singular == 'Share') {
      return '1 Share = 1 Verified Post Share';
    }
    return '1 $singular = 1 Verified Worker Execution';
  }
}
