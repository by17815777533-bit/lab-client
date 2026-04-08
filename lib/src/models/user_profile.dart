class UserProfile {
  UserProfile({
    required this.id,
    required this.username,
    required this.realName,
    required this.role,
    required this.studentId,
    required this.college,
    required this.major,
    required this.grade,
    required this.phone,
    required this.email,
    required this.avatar,
    required this.resume,
    required this.labId,
    required this.canEdit,
    required this.status,
    required this.primaryIdentity,
    required this.labMemberRole,
    required this.managedCollegeId,
    required this.schoolDirector,
    required this.collegeManager,
    required this.labManager,
    required this.platformPostCodes,
  });

  final int id;
  final String username;
  final String realName;
  final String role;
  final String? studentId;
  final String? college;
  final String? major;
  final String? grade;
  final String? phone;
  final String? email;
  final String? avatar;
  final String? resume;
  final int? labId;
  final int? canEdit;
  final int? status;
  final String? primaryIdentity;
  final String? labMemberRole;
  final int? managedCollegeId;
  final bool schoolDirector;
  final bool collegeManager;
  final bool labManager;
  final List<String> platformPostCodes;

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get hasResume => (resume ?? '').trim().isNotEmpty;
  String get initials =>
      realName.trim().isEmpty ? 'U' : realName.trim().substring(0, 1);
  String get accountValue => isStudent ? (studentId ?? username) : username;

  String get roleLabel {
    switch (role) {
      case 'student':
        return '学生账号';
      case 'teacher':
        return '教师账号';
      case 'super_admin':
        return '学校管理员';
      case 'admin':
        return '学院 / 实验室管理员';
      default:
        return role;
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      realName: json['realName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      college: json['college']?.toString(),
      major: json['major']?.toString(),
      grade: json['grade']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      resume: json['resume']?.toString(),
      labId: (json['labId'] as num?)?.toInt(),
      canEdit: (json['canEdit'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
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

  UserProfile copyWith({
    String? realName,
    String? email,
    String? major,
    String? avatar,
    String? resume,
  }) {
    return UserProfile(
      id: id,
      username: username,
      realName: realName ?? this.realName,
      role: role,
      studentId: studentId,
      college: college,
      major: major ?? this.major,
      grade: grade,
      phone: phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      resume: resume ?? this.resume,
      labId: labId,
      canEdit: canEdit,
      status: status,
      primaryIdentity: primaryIdentity,
      labMemberRole: labMemberRole,
      managedCollegeId: managedCollegeId,
      schoolDirector: schoolDirector,
      collegeManager: collegeManager,
      labManager: labManager,
      platformPostCodes: platformPostCodes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'realName': realName,
      'role': role,
      'studentId': studentId,
      'college': college,
      'major': major,
      'grade': grade,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'resume': resume,
      'labId': labId,
      'canEdit': canEdit,
      'status': status,
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
