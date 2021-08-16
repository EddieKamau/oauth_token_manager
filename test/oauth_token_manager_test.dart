import 'package:mockito/mockito.dart';
import 'package:oauth_token_manager/oauth_token_manager.dart';
import 'package:test/test.dart';

class MockTokenManager extends Mock implements TokenManager{

  MockTokenManager(this.consumerKey, this.consumerSecret, this.tokenUrl);

  @override
  String consumerKey;
  @override
  String consumerSecret;
  @override
  String tokenUrl;

  @override
  Future<String> fetchToken(GrantType grantType, [String? username, String? password, String? state])async {
    try {
      Uri.parse(tokenUrl);
    } catch (e) {
      rethrow;
    }
    if (grantType == GrantType.password && (username == null || password == null)) {
      throw BadRequest();
    } else if(!(consumerKey == 'key' && consumerSecret == 'secret')){
      throw Unauthorized();
    }else{
      return 'token';
    }
  }
  
}

void main() {
  group('A group of tests', () {
    final tokenManager = MockTokenManager('key', 'secret', 'http://127.0.0.1');

    setUp(() {
      // Additional setup goes here.
    });

    test('Correct', ()async {
      expect(await tokenManager.fetchToken(GrantType.client_credentials), 'token');
    });
    
    test('Unauthorized', ()async {
      tokenManager.consumerSecret = 'false';
      expect(()async => await tokenManager.fetchToken(GrantType.client_credentials), throwsA(isA<Unauthorized>()));
    });
  });
}
