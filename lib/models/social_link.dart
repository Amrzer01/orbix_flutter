class SocialLink {
  final String id;
  final String userId;
  final String platformName;
  final String username;
  final String iconClass;
  final String bgColor;
  final String textColor;
  final bool isActive;
  final int sortOrder;
  final String? iconUrl; // ← أضف ده

  SocialLink({
    required this.id,
    required this.userId,
    required this.platformName,
    required this.username,
    required this.iconClass,
    required this.bgColor,
    required this.textColor,
    required this.isActive,
    required this.sortOrder,
    this.iconUrl,
  });

  factory SocialLink.fromMap(Map<String, dynamic> map, String id) {
    return SocialLink(
      id: id,
      userId: map['user_id'] ?? '',
      platformName: map['platform_name'] ?? '',
      username: map['username'] ?? '',
      iconClass: map['icon_class'] ?? '',
      bgColor: map['bg_color'] ?? '#101112',
      textColor: map['text_color'] ?? '#FFFFFF',
      isActive: map['is_active'] ?? true,
      sortOrder: map['sort_order'] ?? 0,
      iconUrl: map['icon_url'], // ← أضف ده
    );
  }
}