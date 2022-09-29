module main

import net.smtp
import vweb
import vweb.sse
import time { Time }
import rand { ulid }
import os
import v.ast
import ui_kit { Action, Component, Dashboard, Navbar, Sidebar, Router, Route, Footer, Login}
import crypto.rand as crypto_rand
import sqlite
import freeflowuniverse.crystallib.publisher2 { Publisher, User, Email }


// login page, asks for email, creates cookie with email
// if receives requisite, checks if user meets requisite
// if requisite is auth_required, loads authentication page
// if receives sitename, redirects to site page
['/login/:url/:requisite']
pub fn (mut app App) login(sitename string, requisite string) vweb.Result {

	if app.get_header('Hx-Request') != 'true' {
		return app.index()
	}

	referer := app.get_header('Referer')

	println("debugz: $app.req")

	mut login_action := Action {
		label: 'Continue'
		route: '/sites/preview/$sitename/'
		target: '#dashboard-container'
	}
	
	if requisite == 'auth_required' {
		login_action.route = '/authenticate/$sitename'
	}
	
	login := Login {
		heading: 'Sign in to publisher'
		login: login_action
	}
		//return app.index()

	return $vweb.html()
}

pub fn (mut app App) login_action() vweb.Result {
	if true {
		// send_verification_email()
		// return app.auth_verify()
	}
	return app.html('')
}

// TODO: address based request limits recognition to prevent brute
// TODO: max allowed request per seccond to prevent dos
// if 
["/auth_verify"]
pub fn (mut app App) auth_verify() vweb.Result {
	token := app.get_cookie('token') or { '' }
	user := get_user(token) or { User {} }
	email := user.emails[0].address

	// new_email := Email {
	// 	address: email
	// 	authenticated: false
	// }
	// new_user := User { name: email, emails: [new_email] }

	// token := make_token(new_user)
	// app.set_cookie(name: 'token', value: token)

	// $if debug {
	// 	eprintln(@FN + ':\nCreated email cookie for: $email')
	// }

	// app.user = new_user
	// app.email = email
	// lock app.publisher {
	// 	if ! app.publisher.users.keys().contains(email) {
	// 		app.publisher.user_add(email)
	// 	}
	// }
	
	new_auth := send_verification_email(email)
	lock app.authenticators {
		app.authenticators[email] = new_auth
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
