import 'portal_resolver.dart';

const Set<String> publicPaths = <String>{
  '/',
  '/login',
  '/register',
  '/teacher-register',
  '/password-reset',
};

bool isPublicPath(String path) => publicPaths.contains(path);

PortalType? portalTypeForPath(String path) => resolvePortalTypeFromPath(path);
