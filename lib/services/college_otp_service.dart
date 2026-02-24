import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

/// Result of sending an OTP to the user's college email.
enum OtpSendResult { success, limitReached, failed }

/// Result of verifying an OTP the user entered.
enum OtpVerifyResult { verified, wrongCode, expired, failed }

class CollegeOtpService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  static final CollegeOtpService _instance = CollegeOtpService._internal();
  factory CollegeOtpService() => _instance;
  CollegeOtpService._internal();

  /// Send a 6-digit OTP to the given college email
  /// by invoking the 'send-college-otp' edge function.
  Future<OtpSendResult> sendOtp(String userId, String collegeEmail) async {
    try {
      debugPrint('📧 [CollegeOtpService] Sending OTP to $collegeEmail');

      final session = _client.auth.currentSession;
      if (session == null) {
        debugPrint('⚠️ [CollegeOtpService] No active session');
        return OtpSendResult.failed;
      }

      final response = await _client.functions.invoke(
        'send-college-otp',
        body: {
          'user_id': userId,
          'college_email': collegeEmail,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      final data = response.data;
      debugPrint('📥 [CollegeOtpService] Response status: ${response.status}');
      debugPrint('📥 [CollegeOtpService] Response data: $data');

      if (data is Map) {
        if (data['limit_reached'] == true) {
          debugPrint('🚫 [CollegeOtpService] Daily limit reached');
          return OtpSendResult.limitReached;
        }
        if (data['success'] == true) {
          debugPrint('✅ [CollegeOtpService] OTP sent successfully');
          return OtpSendResult.success;
        }
      }

      debugPrint('⚠️ [CollegeOtpService] Unexpected response: $data');
      return OtpSendResult.failed;
    } on FunctionException catch (e) {
      // Edge function returned non-2xx status — parse the details
      debugPrint('❌ [CollegeOtpService] FunctionException:');
      debugPrint('   status: ${e.status}');
      debugPrint('   details: ${e.details}');
      debugPrint('   reasonPhrase: ${e.reasonPhrase}');

      final details = e.details;
      if (details is Map) {
        // Check if the limit was reached (returned as 429)
        if (details['limit_reached'] == true) {
          return OtpSendResult.limitReached;
        }
        // Log the actual error from the edge function
        debugPrint('   error msg: ${details['error']}');
      }

      return OtpSendResult.failed;
    } catch (e) {
      debugPrint('❌ [CollegeOtpService] sendOtp error: $e');
      return OtpSendResult.failed;
    }
  }

  /// Verify the OTP code entered by the user.
  /// Checks the latest unused, non-expired OTP for this user.
  Future<OtpVerifyResult> verifyOtp(String userId, String enteredCode) async {
    try {
      debugPrint('🔢 [CollegeOtpService] Verifying OTP for user $userId');

      final response = await _client
          .from('college_email_otps')
          .select()
          .eq('user_id', userId)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('⏰ [CollegeOtpService] No valid OTP found (expired or none)');
        return OtpVerifyResult.expired;
      }

      final storedCode = response['otp_code'] as String;

      if (storedCode == enteredCode.trim()) {
        // Mark OTP as used
        await _client
            .from('college_email_otps')
            .update({'is_used': true})
            .eq('id', response['id']);
        debugPrint('✅ [CollegeOtpService] OTP verified successfully');
        return OtpVerifyResult.verified;
      } else {
        debugPrint('❌ [CollegeOtpService] Wrong code entered');
        return OtpVerifyResult.wrongCode;
      }
    } catch (e) {
      debugPrint('❌ [CollegeOtpService] verifyOtp error: $e');
      return OtpVerifyResult.failed;
    }
  }
}
