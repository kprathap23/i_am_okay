import '../fragments.dart';

const String getUsersQuery = """
  query GetUsers(\$where: UserQueryInput) {
    users(where: \$where) {
      ...UserFields
    }
  }
  $userFragment
""";

const String checkUserExistsQuery = """
  query CheckUserExists(\$mobileNumber: String, \$email: String) {
    checkUserExists(mobileNumber: \$mobileNumber, email: \$email)
  }
""";

const String getUserQuery = """
  query GetUser(\$id: String!) {
    user(id: \$id) {
      ...UserFields
    }
  }
  $userFragment
""";
