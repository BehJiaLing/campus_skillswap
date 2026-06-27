class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.emailVerified,
  });

  final String id;
  final String? email;
  final bool emailVerified;
}
