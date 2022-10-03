module main

import net.smtp
import vweb
import vweb.sse { SSEMessage }
import time { Time }
import rand { ulid }
import os
import v.ast
import ui_kit { Action, Component, Dashboard, Navbar, Sidebar, Router, Route, Footer, Login}
import crypto.rand as crypto_rand
import sqlite
import freeflowuniverse.crystallib.publisher2 { Publisher, User, Email }


// Root auth route, handles login, verification, and redirect
['/auth/:requisite']
pub fn (mut app App) auth(requisite string) vweb.Result {

	url := app.get_header('Referer')
	mut route := url.split('//')[1].all_after_first('/')
	mut satisfied := false

	$if debug {
		eprintln(@FN + ':\nAuth request from: $url')
		eprintln('Auth Requisite: $requisite')
	}	

	if requisite == 'email_required' {
		if app.user.emails.len == 0 {
			route = '/auth_login'
		} else {
			satisfied = true
		}
	} 
	
	if requisite == 'auth_required' {
		if app.user.emails.any(!it.authenticated) {
			route = '/auth_verify'
		} else {
			satisfied = true
		}
	}

	// Redirect (via hx-location) to route if requisite satisfed
	if satisfied {
		target := app.get_header('Hx-Target')
			if target != "" {
				app.add_header('HX-Location', '{"path":"/$route", "target":"#$target"}')
			} else {
				app.add_header('HX-Location', '{"path":"/$route"}')
			}
		return app.ok('')
	}

	return $vweb.html()
}

// login page, asks for email, creates cookie with email
pub fn (mut app App) auth_login() vweb.Result {

	url := app.get_header('Referer')
	mut route := url.split('//')[1].all_after_first('/')

	if app.get_header('Hx-Request') != 'true' {
		return app.index()
	}

	mut login_action := Action {
		label: 'Continue'
		route: '/auth/email_required'
	}
	
	login := Login {
		heading: 'Sign in to publisher'
		login: login_action
	}

	return $vweb.html()
}

// TODO: address based request limits recognition to prevent brute
// TODO: max allowed request per seccond to prevent dos
// sends verification email, returns verify email page
["/auth_verify"]
pub fn (mut app App) auth_verify() vweb.Result {
	token := app.get_cookie('token') or { '' }
	user := get_user(token) or { User {} }
	email := user.emails[0].address

	new_auth := send_verification_email(email)
	lock app.authenticators {
		app.authenticators[email] = new_auth
	}

	return $vweb.html()
}

// route of email verification link, random cypher
// authenticates if email/cypher combo correct in 3 tries & 3min
["/authenticate/:email/:cypher"; get]
pub fn (mut app App) authenticate(email string, cypher string) vweb.Result {
	lock app.authenticators {
		mut authenticator := app.authenticators[email]
		if cypher == authenticator.auth_code.hex() {
			if authenticator.attempts < 3 {
				$if debug {
					eprintln(@FN + ':\nUser authenticated email: $email')
				}
			}
			authenticator.authenticated = true
		} else {
			authenticator.attempts += 1
		}
	}
	return app.text("")
}

pub fn (mut app App) insert_auth_listener() vweb.Result {
	email := app.user.emails[0]
	return app.html('hx-sse="connect:/auth_update/$email"')
}

// Updates authentication status by sending server sent event
["/auth_update/:email"]
pub fn (mut app App) auth_update(email string) vweb.Result {	

	mut session := sse.new_connection(app.conn)
	session.start() or { return app.server_error(501) }

	$if debug {
		eprintln(@FN + ':\nWaiting authentication for email: $email')
	}

	// checks if email is authenticated every 2 seconds
	// inspired from https://github.com/vlang/v/blob/master/examples/vweb/server_sent_events/server.v
	for {
		lock app.authenticators{
			if app.authenticators[email].authenticated {
				data := '{"time": "$time.now().str()", "random_id": "$rand.ulid()"}'
				//? for some reason htmx doesn't pick up first sse
				msg := SSEMessage{event: 'email_authenticated', data: data}
				session.send_message(msg) or { return app.server_error(501) }
				session.send_message(msg) or { return app.server_error(501) }
				app.authenticators[email].authenticated = false
			}
		}
		time.sleep(2 * time.second)
	}

	return app.server_error(501)
}
