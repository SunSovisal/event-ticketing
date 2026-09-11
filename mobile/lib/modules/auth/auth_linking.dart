String? resolveAccountEmailForLinking({
  String? passwordProviderEmail,
  String? firebaseEmail,
  String? profileEmail,
}) {
  for (final value in [passwordProviderEmail, firebaseEmail, profileEmail]) {
    final email = value?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
  }
  return null;
}

/// True when both emails are present and differ
/// Empty values are not treated as a mismatch
bool emailsDifferForLinking(String? accountEmail, String? incomingEmail) {
  final account = accountEmail?.trim().toLowerCase() ?? '';
  final incoming = incomingEmail?.trim().toLowerCase() ?? '';
  if (account.isEmpty || incoming.isEmpty) {
    return false;
  }
  return account != incoming;
}
