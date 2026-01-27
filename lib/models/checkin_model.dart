class CheckIn {
  final String id;
  final String userId;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? metadata;
  final DateTime? timestamp;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CheckIn({
    required this.id,
    required this.userId,
    this.location,
    this.metadata,
    this.timestamp,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as String,
      userId: json['userId'] as String,
      location: json['location'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      status: json['status'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'location': location,
      'metadata': metadata,
      'timestamp': timestamp?.toIso8601String(),
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
