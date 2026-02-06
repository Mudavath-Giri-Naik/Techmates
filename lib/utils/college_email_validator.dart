class CollegeEmailValidator {
  static const allowedDomains = [
    'mvgrce.edu.in',
    'iitb.ac.in',
    'nitw.ac.in',
  ];

  static bool isValid(String email) {
    return allowedDomains.any((d) => email.endsWith(d));
  }
}
