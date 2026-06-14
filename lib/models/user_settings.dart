enum CameraQuality {
  low,
  medium,
  high;

  static CameraQuality fromString(String? value) {
    return CameraQuality.values.firstWhere(
      (quality) => quality.name == value,
      orElse: () => CameraQuality.high,
    );
  }
}

class UserSettings {
  const UserSettings({
    required this.cameraQuality,
    required this.darkMode,
    required this.notifications,
  });

  final CameraQuality cameraQuality;
  final bool darkMode;
  final bool notifications;

  static const defaults = UserSettings(
    cameraQuality: CameraQuality.high,
    darkMode: true,
    notifications: false,
  );

  factory UserSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return UserSettings(
      cameraQuality:
          CameraQuality.fromString(json['camera_quality'] as String?),
      darkMode: json['dark_mode'] as bool? ?? true,
      notifications: json['notifications_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'camera_quality': cameraQuality.name,
      'dark_mode': darkMode,
      'notifications_enabled': notifications,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  UserSettings copyWith({
    CameraQuality? cameraQuality,
    bool? darkMode,
    bool? notifications,
  }) {
    return UserSettings(
      cameraQuality: cameraQuality ?? this.cameraQuality,
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
    );
  }
}
