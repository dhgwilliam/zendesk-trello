include Trello::Authorization

Trello::Authorization.const_set :AuthPolicy, OAuthPolicy
OAuthPolicy.consumer_credential = OAuthCredential.new '09e030817ea39832a49f8d12d08482b8', 'd4276da2e1ed586fcc58f3c0cc6f597f3c0e68b91f622b2de191b58a59afa062'
OAuthPolicy.token = OAuthCredential.new '0216a1ff1bb2f00022dc0d4ecbd6431270bd053245ced2d6310e09b64ed22f7f', nil

