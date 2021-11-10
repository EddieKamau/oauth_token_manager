import 'dart:io';

import 'package:oauth_token_manager/oauth_token_manager.dart';

void main()async {
  var tokenManager = TokenManager(
    consumerKey: 'consumerKey', consumerSecret: 'consumerSecret', authUrl: 'http://127.0.0.1'
  );
  try{
    await tokenManager.fetchToken(GrantType.client_credentials);
  }on Unauthorized catch (e){
    print(e);
  }on BadRequest catch (e){
    print(e);
  }on InternalServerError catch (e){
    print(e);
  }on SocketException catch (e){
    print("Cann't reach server");
    print(e);
  }on ArgumentError catch (e){
    print('ArgumentError; check your url');
    print(e);
  } catch (e){
    print(e);
  }



}
