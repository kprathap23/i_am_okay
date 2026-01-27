import '../fragments.dart';

const String createUserMutation = """
  mutation CreateUser(\$input: UserInsertInput!) {
    createUser(input: \$input) {
      ...UserFields
    }
  }
  $userFragment
""";

const String updateUserMutation = """
  mutation UpdateUser(\$id: String!, \$input: UserUpdateInput!) {
    updateUser(id: \$id, input: \$input) {
      ...UserFields
    }
  }
  $userFragment
""";

const String deleteUserMutation = """
  mutation DeleteUser(\$id: String!) {
    deleteUser(id: \$id)
  }
""";
