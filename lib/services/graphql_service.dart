import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import '../gql/mutations/auth_mutations.dart';
import '../gql/queries/user_queries.dart';
import '../gql/queries/checkin_queries.dart';
import '../gql/mutations/user_mutations.dart';
import '../gql/mutations/checkin_mutations.dart';

import '../models/user_model.dart';
import '../models/checkin_model.dart';

class GraphQLService {
  static final HttpLink _httpLink = HttpLink(
    Platform.isAndroid 
        ? 'http://10.0.2.2:5200/graphql' 
        : 'http://localhost:5200/graphql',
  );

  static const _storage = FlutterSecureStorage();

  static ValueNotifier<GraphQLClient> initClient() {
    final AuthLink authLink = AuthLink(
      getToken: () async {
        final token = await _storage.read(key: 'auth_token');
        return token != null ? 'Bearer $token' : null;
      },
    );

    final Link link = authLink.concat(_httpLink);

    return ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    );
  }

  static Future<GraphQLClient> getClient() async {
    final AuthLink authLink = AuthLink(
      getToken: () async {
        final token = await _storage.read(key: 'auth_token');
        return token != null ? 'Bearer $token' : null;
      },
    );

    final Link link = authLink.concat(_httpLink);

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  static Future<String?> requestOtp(String mobile) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(requestOtpMutation),
        variables: {'mobile': mobile},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['requestOtp'] as String?;
  }

  static Future<AuthPayload> verifyOtp(String mobile, String otp) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(verifyOtpMutation),
        variables: {
          'mobile': mobile,
          'otp': otp,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return AuthPayload.fromJson(result.data?['verifyOtp']);
  }

  // User Queries
  static Future<User?> getUser(String id) async {
    final client = await getClient();
    final result = await client.query(
      QueryOptions(
        document: gql(getUserQuery),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['user'];
    return data != null ? User.fromJson(data) : null;
  }

  static Future<List<User>> getUsers({Map<String, dynamic>? where}) async {
    final client = await getClient();
    final result = await client.query(
      QueryOptions(
        document: gql(getUsersQuery),
        variables: {'where': where},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['users'] as List<dynamic>?;
    return data?.map((e) => User.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  // User Mutations
  static Future<User> createUser(Map<String, dynamic> input) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(createUserMutation),
        variables: {'input': input},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return User.fromJson(result.data?['createUser']);
  }

  static Future<User?> updateUser(String id, Map<String, dynamic> input) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(updateUserMutation),
        variables: {
          'id': id,
          'input': input,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['updateUser'];
    return data != null ? User.fromJson(data) : null;
  }

  static Future<bool> deleteUser(String id) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(deleteUserMutation),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['deleteUser'] as bool;
  }

  // CheckIn Queries
  static Future<CheckIn?> getCheckIn(String id) async {
    final client = await getClient();
    final result = await client.query(
      QueryOptions(
        document: gql(getCheckInQuery),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['checkIn'];
    return data != null ? CheckIn.fromJson(data) : null;
  }

  static Future<List<CheckIn>> getCheckIns({Map<String, dynamic>? where}) async {
    final client = await getClient();
    final result = await client.query(
      QueryOptions(
        document: gql(getCheckInsQuery),
        variables: {'where': where},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['checkIns'] as List<dynamic>?;
    return data?.map((e) => CheckIn.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  // CheckIn Mutations
  static Future<CheckIn> createCheckIn(Map<String, dynamic> input) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(createCheckInMutation),
        variables: {'input': input},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return CheckIn.fromJson(result.data?['createCheckIn']);
  }

  static Future<CheckIn?> updateCheckIn(String id, Map<String, dynamic> input) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(updateCheckInMutation),
        variables: {
          'id': id,
          'input': input,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['updateCheckIn'];
    return data != null ? CheckIn.fromJson(data) : null;
  }

  static Future<bool> deleteCheckIn(String id) async {
    final client = await getClient();
    final result = await client.mutate(
      MutationOptions(
        document: gql(deleteCheckInMutation),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['deleteCheckIn'] as bool;
  }
}
