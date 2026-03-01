import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Rewrites Supabase storage URLs to go through the Cloudflare proxy.
///
/// URLs stored in the database reference `hmcxfkirqqifahhbipdt.supabase.co`
/// directly, which is blocked on Indian mobile data. This function replaces
/// the domain with the proxy URL from the .env file.
const _originalHost = 'hmcxfkirqqifahhbipdt.supabase.co';

String? proxyUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  if (!url.contains(_originalHost)) return url;

  final proxyHost = dotenv.env['SUPABASE_URL'] ?? 'https://api.girinaik.in';
  // Extract just the host from the proxy URL (remove https://)
  final proxyHostClean = proxyHost.replaceFirst('https://', '').replaceFirst('http://', '');

  return url.replaceAll(_originalHost, proxyHostClean);
}
