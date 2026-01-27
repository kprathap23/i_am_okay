import '../fragments.dart';

const String createCheckInMutation = """
  mutation CreateCheckIn(\$input: CheckInInsertInput!) {
    createCheckIn(input: \$input) {
      ...CheckInFields
    }
  }
  $checkInFragment
""";

const String updateCheckInMutation = """
  mutation UpdateCheckIn(\$id: String!, \$input: CheckInUpdateInput!) {
    updateCheckIn(id: \$id, input: \$input) {
      ...CheckInFields
    }
  }
  $checkInFragment
""";

const String deleteCheckInMutation = """
  mutation DeleteCheckIn(\$id: String!) {
    deleteCheckIn(id: \$id)
  }
""";
