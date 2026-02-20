class AuthPayload {
  final String token;
  final User? user;

  AuthPayload({
    required this.token,
    this.user,
  });

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    return AuthPayload(
      token: json['token'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user?.toJson(),
    };
  }
}

class User {
  final String id;
  final String mobileNumber;
  final String? email;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Name? name;
  final Address? address;
  final List<EmergencyContact> emergencyContacts;
  final ReminderSettings? reminderSettings;

  User({
    required this.id,
    required this.mobileNumber,
    this.email,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.address,
    this.emergencyContacts = const [],
    this.reminderSettings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      mobileNumber: json['mobileNumber'] as String,
      email: json['email'] as String?,
      role: json['role'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      name: json['name'] != null
          ? Name.fromJson(json['name'] as Map<String, dynamic>)
          : null,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reminderSettings: json['reminderSettings'] != null
          ? ReminderSettings.fromJson(
              json['reminderSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobileNumber': mobileNumber,
      'email': email,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'name': name?.toJson(),
      'address': address?.toJson(),
      'emergencyContacts':
          emergencyContacts.map((e) => e.toJson()).toList(),
      'reminderSettings': reminderSettings?.toJson(),
    };
  }
}

class Name {
  final String? firstName;
  final String? lastName;
  final String? alias;

  Name({
    this.firstName,
    this.lastName,
    this.alias,
  });

  factory Name.fromJson(Map<String, dynamic> json) {
    return Name(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      alias: json['alias'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'alias': alias,
    };
  }
}

class Address {
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? zipCode;

  Address({
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address1': address1,
      'address2': address2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }
}

class EmergencyContact {
  final String? name;
  final String? relation;
  final String? phone;
  final String? email;

  EmergencyContact({
    this.name,
    this.relation,
    this.phone,
    this.email,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String?,
      relation: json['relation'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
      'email': email,
    };
  }
}

class ReminderSettings {
  final String? checkInTime;
  final bool? isPaused;
  final DateTime? pausedUntil;

  ReminderSettings({
    this.checkInTime,
    this.isPaused,
    this.pausedUntil,
  });

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      checkInTime: json['checkInTime'] as String?,
      isPaused: json['isPaused'] as bool?,
      pausedUntil: json['pausedUntil'] != null
          ? DateTime.tryParse(json['pausedUntil'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkInTime': checkInTime,
      'isPaused': isPaused,
      'pausedUntil': pausedUntil?.toIso8601String(),
    };
  }
}
