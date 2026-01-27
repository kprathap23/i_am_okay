import '../fragments.dart';

const String getCheckInsQuery = """
  query GetCheckIns(\$where: CheckInQueryInput) {
    checkIns(where: \$where) {
      ...CheckInFields
    }
  }
  $checkInFragment
""";

const String getCheckInQuery = """
  query GetCheckIn(\$id: String!) {
    checkIn(id: \$id) {
      ...CheckInFields
    }
  }
  $checkInFragment
""";
