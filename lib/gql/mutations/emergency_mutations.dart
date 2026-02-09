const String sendEmergencySmsMutation = """
  mutation SendEmergencySms(\$location: String) {
    sendEmergencySms(location: \$location)
  }
""";
