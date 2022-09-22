module main

import crypto.hmac
import crypto.sha256
import crypto.bcrypt
import encoding.base64
import json
import time
import os
import freeflowuniverse.crystallib.publisher2 { Publisher, User }


struct JwtHeader {
	alg string
	typ string
}

struct JwtPayload {
	sub         string    // (subject) = Entidade à quem o token pertence, normalmente o ID do usuário;
	iss         string    // (issuer) = Emissor do token;
	exp         string    // (expiration) = Timestamp de quando o token irá expirar;
	iat         time.Time // (issued at) = Timestamp de quando o token foi criado;
	aud         string    // (audience) = Destinatário do token, representa a aplicação que irá usá-lo.
	name        string
	roles       string
	permissions string
}

fn make_token(user User) string {
	
	$if debug {
		eprintln(@FN + ':\nCreating cookie token for user: $user')
	}	

	secret := os.getenv('SECRET_KEY')
	jwt_header := JwtHeader{'HS256', 'JWT'}
	user_email := user.emails[0]
	jwt_payload := JwtPayload{
		sub: '$user.name'
		name: '$user_email'
		iat: time.now()
	}

	header := base64.url_encode(json.encode(jwt_header).bytes())
	payload := base64.url_encode(json.encode(jwt_payload).bytes())
	signature := base64.url_encode(hmac.new(secret.bytes(), '${header}.$payload'.bytes(),
		sha256.sum, sha256.block_size).bytestr().bytes())

	jwt := '${header}.${payload}.$signature'

	return jwt
}

fn auth_verify(token string) bool {
	secret := os.getenv('SECRET_KEY')
	token_split := token.split('.')

	signature_mirror := hmac.new(secret.bytes(), '${token_split[0]}.${token_split[1]}'.bytes(),
		sha256.sum, sha256.block_size).bytestr().bytes()

	signature_from_token := base64.url_decode(token_split[2])

	return hmac.equal(signature_from_token, signature_mirror)
}

fn get_user(token string) username_string {
	secret := os.getenv('SECRET_KEY')
	println("secret $secret \n token: $token")
	token_split := token.split('.')

	signature_mirror := hmac.new(secret.bytes(), '${token_split[0]}.${token_split[1]}'.bytes(),
		sha256.sum, sha256.block_size).bytestr().bytes()

	signature_from_token := base64.url_decode(token_split[2])

	return hmac.equal(signature_from_token, signature_mirror)
}
