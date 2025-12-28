class Group {
  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final List<String> memberIds; // List of user IDs
  final String creatorId; // User ID of the group creator
  final DateTime createdAt;
  final DateTime? updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.memberIds,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert Group to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'memberIds': memberIds,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create Group from Map
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      avatarUrl: map['avatarUrl'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      creatorId: map['creatorId'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Create Group from JSON
  factory Group.fromJson(Map<String, dynamic> json) => Group.fromMap(json);
  
  // Convert Group to JSON
  Map<String, dynamic> toJson() => toMap();

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    List<String>? memberIds,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberIds: memberIds ?? this.memberIds,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}