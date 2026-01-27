const String userFragment = """
  fragment UserFields on User {
    id
    mobileNumber
    email
    createdAt
    updatedAt
    name {
      firstName
      lastName
      alias
    }
    address {
      address1
      address2
      city
      state
      zipCode
    }
    emergencyContacts {
      name
      relation
      phone
      email
    }
    reminderSettings {
      checkInTime
      isPaused
      pausedUntil
    }
  }
""";

const String checkInFragment = """
  fragment CheckInFields on CheckIn {
    id
    userId
    location {
      lat
      lng
    }
    metadata {
      source
      deviceInfo
    }
    timestamp
    status
    createdAt
    updatedAt
  }
""";
