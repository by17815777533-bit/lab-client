import '../../models/user_profile.dart';

enum PortalType { public, student, teacher, admin }

PortalType resolvePortalType(UserProfile? profile) {
  if (profile == null) {
    return PortalType.public;
  }
  if (profile.isStudent) {
    return PortalType.student;
  }
  if (profile.isTeacher) {
    return PortalType.teacher;
  }
  if (profile.isAdmin) {
    return PortalType.admin;
  }
  return PortalType.public;
}

PortalType? resolvePortalTypeFromPath(String path) {
  if (path.startsWith('/student')) {
    return PortalType.student;
  }
  if (path.startsWith('/teacher')) {
    return PortalType.teacher;
  }
  if (path.startsWith('/admin')) {
    return PortalType.admin;
  }
  if (path == '/login' ||
      path == '/register' ||
      path == '/teacher-register' ||
      path == '/password-reset' ||
      path == '/') {
    return PortalType.public;
  }
  return null;
}

String resolvePortalHome(PortalType portalType) {
  switch (portalType) {
    case PortalType.student:
      return '/student';
    case PortalType.teacher:
      return '/teacher';
    case PortalType.admin:
      return '/admin';
    case PortalType.public:
      return '/login';
  }
}
