class UserSession {
  UserSession({
    required this.id,
    required this.token,
    required this.username,
    required this.realName,
    required this.role,
    required this.labId,
    required this.avatar,
    required this.primaryIdentity,
    required this.labMemberRole,
    required this.managedCollegeId,
    required this.schoolDirector,
    required this.collegeManager,
    required this.labManager,
    required this.platformPostCodes,
  });

  final int id;
  final String token;
  final String username;
  final String realName;
  final String role;
  final int? labId;
  final String? avatar;
  final String? primaryIdentity;
  final String? labMemberRole;
  final int? managedCollegeId;
  final bool schoolDirector;
  final bool collegeManager;
  final bool labManager;
  final List<String> platformPostCodes;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: (json['id'] as num?)?.toInt() ?? 0,
      token: json['token']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      realName: json['realName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      labId: (json['labId'] as num?)?.toInt(),
      avatar: json['avatar']?.toString(),
      primaryIdentity: json['primaryIdentity']?.toString(),
      labMemberRole: json['labMemberRole']?.toString(),
      managedCollegeId: (json['managedCollegeId'] as num?)?.toInt(),
      schoolDirector: json['schoolDirector'] == true,
      collegeManager: json['collegeManager'] == true,
      labManager: json['labManager'] == true,
      platformPostCodes:
          (json['platformPostCodes'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'token': token,
      'username': username,
      'realName': realName,
      'role': role,
      'labId': labId,
      'avatar': avatar,
      'primaryIdentity': primaryIdentity,
      'labMemberRole': labMemberRole,
      'managedCollegeId': managedCollegeId,
      'schoolDirector': schoolDirector,
      'collegeManager': collegeManager,
      'labManager': labManager,
      'platformPostCodes': platformPostCodes,
    };
  }
}
