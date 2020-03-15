import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../secrets.dart';

class SecureStorageHelper {
  SecureStorageHelper._privateConstructor() {
    this.init();
  }

  static final SecureStorageHelper instance =
      SecureStorageHelper._privateConstructor();

  SharedPreferences prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  String get authToken {
    return prefs.getString('authToken') ?? "";
  }

  String get refreshToken {
    return prefs.getString("refreshToken") ?? "";
  }

  String get lastTokenRefresh {
    return prefs.getString('lastTokenRefresh') ?? "";
  }

  bool get signInStatus {
    if (prefs != null) {
      return prefs.getBool('signedIn') ?? false;
    } else {
      return false;
    }
  }

  Future<bool> needsTokenRefresh() async {
    Duration time =
        (DateTime.now()).difference(DateTime.parse(lastTokenRefresh));
    if (time.inMinutes > 30) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> updateCredentials(
    String authToken,
    String refreshToken,
    String lastTokenRefresh,
    bool signedIn,
  ) async {
    await prefs.setString("authToken", authToken);
    await prefs.setString("refreshToken", refreshToken);
    await prefs.setBool("signedIn", signedIn);
    await prefs.setString("lastTokenRefresh", DateTime.now().toIso8601String());
  }

  Future<void> updateAuthToken(String accessToken) async {
    await prefs.setString("authToken", accessToken);
    await prefs.setString(
      'lastTokenRefresh',
      DateTime.now().toIso8601String(),
    );
    await prefs.setString(
      'signedIn',
      true.toString(),
    );
  }

  Future<void> clearStorage() async {
    await prefs.clear();
  }

  Future<void> performTokenRefresh() async {
    String user = CLIENT_ID;
    String password = "";
    String basicAuth = "Basic " + base64Encode(utf8.encode('$user:$password'));
    final response = await http
        .post(
      "https://www.reddit.com/api/v1/access_token",
      headers: {
        "Authorization": basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: "grant_type=refresh_token&refresh_token=${refreshToken}",
    )
        .catchError((e) {
      this.clearStorage();
    });

    if (response.statusCode == 200) {
      Map<String, dynamic> map = json.decode(response.body);
      // print("Refreshed token: " + map.toString());
      await updateAuthToken(map['access_token']);
    } else {}
  }
}
