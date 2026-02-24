/// Utility to detect personal/free email domains.
/// Use this to block non-college emails during verification.
class EmailValidator {
  static const _blockedDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
    'yahoo.in',
    'rediffmail.com',
    'live.com',
    'msn.com',
    'protonmail.com',
    'tutanota.com',
    'googlemail.com',
  ];

  /// Returns true if the email belongs to a personal/free domain.
  static bool isPersonalEmail(String email) {
    final domain = email.split('@').last.toLowerCase().trim();
    return _blockedDomains.contains(domain);
  }
}
