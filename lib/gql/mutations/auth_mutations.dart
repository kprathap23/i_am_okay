import '../fragments.dart';

const String requestOtpMutation = """
  mutation RequestOTP(\$mobile: String!, \$isRegister: Boolean) {
    requestOtp(mobileNumber: \$mobile, isRegister: \$isRegister)
  }
""";

const String verifyOtpMutation = """
  mutation VerifyOTP(\$mobile: String!, \$otp: String!, \$userDetails: UserInsertInput) {
    verifyOtp(mobileNumber: \$mobile, code: \$otp, userDetails: \$userDetails) {
      token
      user {
        ...UserFields
      }
    }
  }
  $userFragment
""";
