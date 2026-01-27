import '../fragments.dart';

const String requestOtpMutation = """
  mutation RequestOTP(\$mobile: String!) {
    requestOtp(mobileNumber: \$mobile)
  }
""";

const String verifyOtpMutation = """
  mutation VerifyOTP(\$mobile: String!, \$otp: String!) {
    verifyOtp(mobileNumber: \$mobile, code: \$otp) {
      token
      user {
        ...UserFields
      }
    }
  }
  $userFragment
""";
