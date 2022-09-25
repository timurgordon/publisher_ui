module main

import crypto.hmac
import crypto.sha256
import crypto.bcrypt
import encoding.base64
import json
import time
import net.smtp
import crypto.rand as crypto_rand
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
	user		User
}

fn make_token(user User) string {
	
	$if debug {
		eprintln(@FN + ':\nCreating cookie token for user: $user')
	}	

	secret := os.getenv('SECRET_KEY')
	jwt_header := JwtHeader{'HS256', 'JWT'}
	user_email := user.emails[0]
	jwt_payload := JwtPayload{
		user: user
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

fn get_username(token string) string {
	payload := json.decode(JwtPayload, base64.url_decode(token.split('.')[1]).bytestr()) or {
		panic(err)
	}
	return payload.user.name
}

fn send_verification_email(email string) Auth {
	auth_code := crypto_rand.bytes(64) or { panic(err) }
	authenticator := Auth { auth_code: auth_code }

	auth_hex := auth_code.hex()
	expiry_unix := time.now().unix + 180
	timeout := time.new_time(unix: expiry_unix)

	subject := 'Test Subject'
	body := 'Test Body, <a href="localhost:8000/authenticate/$email/$auth_hex">Click to authenticate</a>'
	client_cfg := smtp.Client {
		server: 'smtp.mailtrap.io'
		from: 'verify@tfpublisher.io'
		port: 465
		username: 'e57312ae7c9742'
		password: 'b8dc875d4a0b33'
	}
	send_cfg := smtp.Mail{
		to: email
		subject: subject
		body_type: .html
		body: body
	}
	mut client := smtp.new_client(client_cfg) or { panic('Error creating smtp client: $err') }
	client.send(send_cfg) or { panic('Error resolving email address') }
	client.quit() or { panic('Could not close connection to server')}
	$if debug {
		eprintln(@FN + ':\nSent verification email to: $email')
	}
	return authenticator
}