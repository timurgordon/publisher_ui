module main

import net.smtp
import vweb
import vweb.sse
import time { Time }
import rand { ulid }
import os
import v.ast
import ui_kit { Action, Component, Dashboard, Navbar, Sidebar, Router, Route, Footer}
import crypto.rand as crypto_rand
import sqlite
import freeflowuniverse.crystallib.publisher2 { Publisher, User, Email }

pub fn (mut app App) login() vweb.Result {
	return $vweb.html()
}

// TODO: address based request limits recognition to prevent brute
// TODO: max allowed request per seccond to prevent dos
// 
["/auth_verify"; post]
pub fn (mut app App) auth_verify(email string) vweb.Result {
	new_email := Email {
		address: email
		authenticated: false
	}
	new_user := User { name: email, emails: [new_email] }
	println(app)
	lock app.publisher {
		app.publisher.users[email] = new_user
	}
	token := make_token(new_user)
	app.set_cookie(name: 'token', value: token)

	$if debug {
		eprintln(@FN + ':\nCreated email cookie for: $email')
	}

	app.user = new_user
	app.email = email
	lock app.publisher {
		app.publisher.user_add(email)
	}
	auth_code := crypto_rand.bytes(64) or { panic(err) }
	auth_hex := auth_code.hex()
	lock app.authenticators {
		app.authenticators[email] = Auth {
			auth_code: auth_code
		}
	}
	expiry_unix := time.now().unix + 180
	timeout := time.new_time(unix: expiry_unix)

	to := email
	subject := 'Test Subject'
	body := 'Test Body, <a href="localhost:8000/authenticate/$email/$auth_hex">Click to authenticate</a>'
	client_cfg := smtp.Client{
		server: 'smtp.freesmtpservers.com'
		from: 'verify@tfpublisher.io'
		port: 25
		username: ''
		password: ''
	}
	send_cfg := smtp.Mail{
		to: to
		subject: subject
		body_type: .html
		body: body
	}
	mut client := smtp.new_client(client_cfg) or { panic('Error configuring smtp') }
	client.send(send_cfg) or { panic('Error resolving email address') }
	$if debug {
		eprintln(@FN + ':\nSent verification email to: $email')
	}
	return $vweb.html()
}


["/authenticate/:email/:cypher"; get]
pub fn (mut app App) authenticate(email string, cypher string) vweb.Result {
	lock app.authenticators {
		// read/modify/write b.x
		if cypher == app.authenticators[email].auth_code.hex() {
			$if debug {
				eprintln(@FN + ':\nUser authenticated email: $email')
			}
			app.authenticators[email].authenticated = true
		}
	}
	return app.text("")
}

pub fn (mut app App) insert_auth_listener() vweb.Result {
	email := app.user.emails[0]
	return app.html('hx-sse="connect:/auth_update/$email"')
}


["/auth_update/:email"]
pub fn (mut app App) auth_update(email string) vweb.Result {	

	mut session := sse.new_connection(app.conn)
	// Note: you can setup session.write_timeout and session.headers here
	session.start() or { return app.server_error(501) }

	$if debug {
		eprintln(@FN + ':\nWaiting authentication for email: $email')
	}

	for {
		lock app.authenticators{
			if app.authenticators[email].authenticated {
				data := '{"time": "$time.now().str()", "random_id": "$rand.ulid()"}'
				// for some reason htmx doesn't pick up first sse
				session.send_message(event: 'email_authenticated', data: data) or { return app.server_error(501) }
				session.send_message(event: 'email_authenticated', data: data) or { return app.server_error(501) }
				app.authenticators[email].authenticated = false
				$if debug {
					eprintln(@FN + ':\nSent server side event: email_authenticated')
				}
			}
		}
		time.sleep(1 * time.second)
	}
	return app.server_error(501)
}