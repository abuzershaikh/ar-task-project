export enum TaskType {
    // YouTube Tasks
    YOUTUBE_COMMENT = 'youtube_comment',
    YOUTUBE_WATCH_TIME = 'youtube_watch_time',
    YOUTUBE_SUBSCRIBE = 'youtube_subscribe',
    YOUTUBE_LIKE = 'youtube_like',
    YOUTUBE_SHARE = 'youtube_share',

    // Instagram Tasks
    INSTAGRAM_FOLLOW = 'instagram_follow',
    INSTAGRAM_LIKE = 'instagram_like',
    INSTAGRAM_COMMENT = 'instagram_comment',
    INSTAGRAM_SHARE = 'instagram_share',

    // Twitter Tasks
    TWITTER_FOLLOW = 'twitter_follow',
    TWITTER_RETWEET = 'twitter_retweet',
    TWITTER_LIKE = 'twitter_like',
    TWITTER_COMMENT = 'twitter_comment',

    // Facebook Tasks
    FACEBOOK_LIKE = 'facebook_like',
    FACEBOOK_COMMENT = 'facebook_comment',
    FACEBOOK_SHARE = 'facebook_share',

    // Generic Tasks
    SURVEY = 'survey',
    APP_INSTALL = 'app_install',
    WEBSITE_VISIT = 'website_visit',
    CUSTOM = 'custom'
}

export enum TaskCategory {
    YOUTUBE = 'youtube',
    INSTAGRAM = 'instagram',
    TWITTER = 'twitter',
    FACEBOOK = 'facebook',
    SOCIAL_MEDIA = 'social_media',
    SURVEY = 'survey',
    APP = 'app',
    WEB = 'web',
    CUSTOM = 'custom'
}
