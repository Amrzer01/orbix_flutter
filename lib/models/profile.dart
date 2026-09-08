class Profile {
  final String id;
  final String userId;
  final String avatarUrl;
  final String fullName;
  final String roleType;
  final String bio;
  final bool isPrivate;
  final int connectedCount;
  final String bgColor;

  Profile({
    required this.id,
    required this.userId,
    required this.avatarUrl,
    required this.fullName,
    required this.roleType,
    required this.bio,
    this.isPrivate = false,
    this.connectedCount = 0,
    this.bgColor = 'white',
  });

  factory Profile.fromMap(Map<String, dynamic> data, String documentId) {
    return Profile(
      id: documentId,
      userId: data['user_id'] ?? '',
      avatarUrl: data['avatar_url'] ?? '',
      fullName: data['full_name'] ?? '',
      roleType: data['role_type'] ?? '',
      bio: data['bio'] ?? '',
      isPrivate: data['is_private'] ?? false,
      connectedCount: data['connected_count'] ?? 0,
      bgColor: data['bg_color'] ?? 'white',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'avatar_url': avatarUrl,
      'full_name': fullName,
      'role_type': roleType,
      'bio': bio,
      'is_private': isPrivate,
      'connected_count': connectedCount,
      'bg_color': bgColor,
    };
  }
}
