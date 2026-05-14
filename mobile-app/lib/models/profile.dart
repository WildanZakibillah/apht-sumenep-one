/// Represents a user profile from the `profiles` table.
class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? factoryId;
  final String? warehouseId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.factoryId,
    this.warehouseId,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      factoryId: json['factory_id'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'factory_id': factoryId,
      'warehouse_id': warehouseId,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }

  /// Whether this user has admin-level privileges.
  bool get isAdmin => role == 'super_admin' || role == 'admin_pabrik';

  /// Whether this user is a super administrator.
  bool get isSuperAdmin => role == 'super_admin';

  Profile copyWith({
    String? fullName,
    String? phone,
    String? role,
    String? factoryId,
    String? warehouseId,
    String? avatarUrl,
    bool? isActive,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      factoryId: factoryId ?? this.factoryId,
      warehouseId: warehouseId ?? this.warehouseId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
