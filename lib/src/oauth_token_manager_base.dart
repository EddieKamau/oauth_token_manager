import 'dart:convert';

import 'package:enum_object/enum_object.dart';
import 'package:http/http.dart' as http;

/// 
class TokenManager {
  static final Map<String, TokenManager> _cache = {};

  String consumerKey;
  String consumerSecret;

  String? accessToken;
  String? refreshToken;
  DateTime? expiresAt;
  List<String> scopes = [];

  String authUrl;
  String? callbackUrl;

  factory TokenManager({
    String? tag,
    required String consumerKey, required String consumerSecret, 
    required String authUrl, String? callbackUrl, 
    List<String> scopes = const[]
  }){
    String name = tag ?? consumerKey;
    if(_cache[name] == null) {
      _cache[name] = TokenManager._internal(
        consumerKey: consumerKey, consumerSecret: consumerSecret, scopes: scopes,
        authUrl: authUrl, callbackUrl: callbackUrl
      ); 
    }
    return _cache[name]!;
  }
  factory TokenManager.find(String tag){
    return _cache[tag]!;
  }

  static void delete(String tag){
    _cache.remove(tag);
  }

  TokenManager._internal({
    required this.consumerKey, required this.consumerSecret, required this.authUrl, this.scopes = const[], 
    this.callbackUrl
  });

  bool get isNotExpired{
    if (expiresAt != null) {
      return expiresAt!.isAfter(DateTime.now().subtract(const Duration(minutes: 1)));
    }else{
      return false;
    }
  }

  Future<String> fetchToken(GrantType grantType, [String? username, String? password, String? state])async{

    // check if token exist
    if(accessToken != null && isNotExpired){
      return accessToken!;
    }

    // check if exist but expired then refresh token
    if(refreshToken != null && !isNotExpired){
      grantType = GrantType.refresh_token;
    }

    final Map<String, String> headers = {
            'Content-type' : 'application/x-www-form-urlencoded', 
            'authorization': basicAuthorization
          };

    final String? _grantType = grantType.enumValue;

    final Map<String, dynamic> body = {
            'grant_type' : _grantType, 
            'scope': scopes.join(' ')
          };

    final Encoding? encoding = Encoding.getByName('utf-8');

    // dynamic body
    switch (grantType) {
      case GrantType.password:
        body.addAll({
          'username': username,
          'password': password,
        });
        break;
      case GrantType.refresh_token:
        body.addAll({
          'refresh_token': refreshToken,
        });
        break;
      // TODO: code, implisit, etc.
      default:
    }

    // send request
    try {
      final http.Response _res = await oauth2Request(authUrl, headers, body, encoding);
      switch (_res.statusCode) {
        // sucess
        case 200:
        case 201:
          var _body = json.decode(_res.body);
          accessToken = _body['access_token'];
          refreshToken = _body['refresh_token'];
          scopes = _body['scope'].toString().split(' ');
          expiresAt = DateTime.now().add(Duration(seconds: int.tryParse(_body['expires_in'].toString()) ?? 0));
          return accessToken ?? '';
        case 400:
          throw BadRequest(_res.body);
        case 500:
          throw InternalServerError(_res.body);
        default:
          throw TokenRequestError(_res.statusCode, _res.body);
      }
    } catch (e) {
      rethrow;
    }

  }


  String get basicAuthorization{
    final _base64E = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
    return 'Basic $_base64E';
  }


  Future<http.Response> oauth2Request(String url, Map<String, String> headers, Map<String, dynamic> body, Encoding? encoding)async{
    try {
      return await http.post(Uri.parse(url), headers: headers, body: body, encoding: encoding);
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> basicAuthRequest(String url)async{
    // check if token exist
    if(accessToken != null && isNotExpired){
      return http.Response(
        jsonEncode({'access_token': accessToken}), 
        200
      );
    }
    try {
      var _res = await http.get(Uri.parse(url), headers: <String, String>{'authorization': basicAuthorization});

      if (_res.statusCode == 200) {
          var _body = json.decode(_res.body);
          accessToken = _body['access_token'];
          expiresAt = DateTime.now().add(Duration(seconds: int.tryParse(_body['expires_in'].toString()) ?? 0));
      }

      return _res;
    } catch (e) {
      rethrow;
    }
  }
}

enum GrantType{
  client_credentials,
  password,
  code,
  refresh_token
}


// exceptions
class Unauthorized implements Exception{
  @override
  String toString()=> 'Unauthorized';
}

class InternalServerError implements Exception{
  InternalServerError([this.message]);
  String? message;
  @override
  String toString()=> 'Internal Server Error: ${message ?? ""}';
}

class BadRequest implements Exception{
  BadRequest([this.message]);
  String? message;
  @override
  String toString()=> 'Bad Request: ${message ?? ""}';
}

class TokenRequestError implements Exception{
  TokenRequestError(this.statuscode, [this.message]);
  String? message;
  int statuscode;
  @override
  String toString()=> 'StatusCode: $statuscode, Message: ${message ?? ""}';
}