import 'dart:async';
import 'dart:convert';
import 'package:flutter_session/flutter_session.dart';
import 'package:http/http.dart' as http;

class CustomCognito {
  static const baseUrl = "";
  static const clientId = "";

  String bearerToken;

  Future<bool> cognitoRegister(String email, String phone, String name,
      String birthdate, String referaalCode) async {
    final response = await http.post(Uri.parse(CustomCognito.baseUrl),
        headers: <String, String>{
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.SignUp',
          'Content-Type': 'application/x-amz-json-1.1'
        },
        body: jsonEncode(<String, dynamic>{
          "ClientId": CustomCognito.clientId,
          "Username": phone,
          "Password": "A!a1b2c3d4",
          "UserAttributes": [
            {"Name": "email", "Value": email},
            {"Name": "phone_number", "Value": phone},
            {"Name": "name", "Value": name},
            {"Name": "birthdate", "Value": birthdate},
            {"Name": "custom:referralCode", "Value": referaalCode},
          ]
        }));
    if (response.statusCode == 200) {
      return await cognitoLogin(phone);
    } else if (response.statusCode == 400) {
      dynamic data = jsonDecode(response.body);
      print(data["__type"]);
      return true;
    }
    return false;
  }

  Future<bool> cognitoLogin(String phone) async {
    final response = await http.post(
      Uri.parse(CustomCognito.baseUrl),
      headers: <String, String>{
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
        'Content-Type': 'application/x-amz-json-1.1'
      },
      body: jsonEncode(<String, dynamic>{
        "AuthFlow": "CUSTOM_AUTH",
        "AuthParameters": {"USERNAME": phone},
        "USERNAME": phone,
        "ClientId": CustomCognito.clientId,
        "ClientMetadata": {}
      }),
    );
    if (response.statusCode == 200) {
      // setup token;
      dynamic data = jsonDecode(response.body);
      await FlutterSession().set('state', 'custom_challenge');
      await FlutterSession().set('challengeSession', data['Session']);
      await FlutterSession()
          .set('challengePhone', data['ChallengeParameters']['phone']);
      return true;
    } else if (response.statusCode == 400) {
      dynamic data = jsonDecode(response.body);
      print(data["__type"]);
      return true;
    }
    return false;
    // print(response.body['__type']);
  }

  Future<bool> cognitoRespondToChallenge(String code) async {
    String session = await FlutterSession().get("challengeSession");
    String phone = await FlutterSession().get("challengePhone");
    final response = await http.post(
      Uri.parse(CustomCognito.baseUrl),
      headers: <String, String>{
        'X-Amz-Target':
            'AWSCognitoIdentityProviderService.RespondToAuthChallenge',
        'Content-Type': 'application/x-amz-json-1.1'
      },
      body: jsonEncode(<String, dynamic>{
        "ChallengeName": "CUSTOM_CHALLENGE",
        "ChallengeResponses": {"USERNAME": phone, "ANSWER": code},
        "ClientId": CustomCognito.clientId,
        "Session": session,
      }),
    );
    print('----------------------->');
    print(response.statusCode);
    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body);
      await FlutterSession()
          .set('AccessToken', data['AuthenticationResult']['AccessToken']);
      print("inside");
      return true;
    }
    return false;
    // print(response.statusCode);
  }
}
