module main

import net.smtp
import vweb
import vweb.sse
import time { Time }
import rand { ulid }
import os
import v.ast
import ui_kit { Action, Component, Dashboard, Navbar, Sidebar, Kanban, Footer}
import crypto.rand as crypto_rand
import sqlite
import freeflowuniverse.crystallib.publisher2 { Publisher, User }

const (
	port = 8000
)

struct App {
	vweb.Context
mut:
	user User
	email string = ""
	publisher Publisher
	authenticators shared map[string]Auth
}

struct AccessGroup {
	name string
}

struct Auth {
	max_attempts int = 3
mut:
	timeout Time
	auth_code []u8
	attempts int = 0
	authenticated bool = false
}

fn main() {
	mut publisher := publisher2.get()?
	mut app := &App {
		publisher: publisher
	}
	app.mount_static_folder_at(os.resource_abs_path('.'), '/')
	vweb.run(app, port)
}

pub fn (mut app App) index() vweb.Result {
	
	return $vweb.html()
}

pub fn (mut app App) login() vweb.Result {
	return $vweb.html()
}

// TODO: address based request limits recognition to prevent brute
// TODO: max allowed request per seccond to prevent dos
// 
["/send_auth"; post]
pub fn (mut app App) send_auth_email(email string) vweb.Result {
	app.user = User { emails: [email] }
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
	return app.html('    
	<span hx-get="/auth_verify" hx-target="#login-form" hx-trigger="load"></span>
	<div hx-sse="connect:/auth_update/$email">
		<span hx-trigger="sse:email_authenticated" hx-get="/dashboard" hx-target="#page-container"></span>
	</div>')
}

pub fn  (mut app App) auth_verify () vweb.Result {
	return $vweb.html()
}

["/authenticate/:email/:cypher"; get]
pub fn (mut app App) authenticate(email string, cypher string) vweb.Result {
	lock app.authenticators {
		// read/modify/write b.x
		if cypher == app.authenticators[email].auth_code.hex() {
			println("yay")
			app.authenticators[email].authenticated = true
			new_user := User {
				emails: [email]
			}
			app.publisher.users[email] = new_user
		}
	}
	return app.text("")
}

pub fn (mut app App) await_authentication() vweb.Result {
	return app.html(
		'<span>Awaiting authentication</span>'
	)
}

["/auth_update/:email"]
pub fn (mut app App) auth_update(email string) vweb.Result {
	println('app here: $app')

	mut session := sse.new_connection(app.conn)
	// Note: you can setup session.write_timeout and session.headers here
	session.start() or { return app.server_error(501) }

	for {
		lock app.authenticators{
			println(app.authenticators[email])
			if app.authenticators[email].authenticated {
				data := '{"time": "$time.now().str()", "random_id": "$rand.ulid()"}'
				session.send_message(event: 'email_authenticated', data: data) or { return app.server_error(501) }
				println('> sent event: $data')
			}
		}
		time.sleep(1 * time.second)
	}
	return app.server_error(501)
}

pub fn (mut app App) dashboard_sidebar() vweb.Result {

	home_action := Action {
		label: "Home",
		icon: "#",
		route: "home",
		swap: "content_container"
	}

	kanban_action := Action {
		label: "Kanban",
		icon: "#",
		route: "kanban",
		swap: "content_container"
	}

	side_menu := [
		home_action,
		kanban_action
	]

	sidebar := Sidebar {
		menu: side_menu
	}
	return $vweb.html()
}

// from vweb_example.v
pub fn (mut app App) create_cookie() vweb.Result {
	token := make_token(app.user)
	app.set_cookie(name: 'token', value: token)
	return app.text('Response Headers\n$app.header')
}

pub fn (mut app App) dashboard() vweb.Result {

	// token := app.get_header('token')

	// if !auth_verify(token) {
	// 	app.set_status(401, '')
	// 	return app.text('Not valid token')
	// }

	footer := Footer {
		links: []
	}

	dashboard := Dashboard {
		logo_path: '#'
		navbar: 'dashboard_navbar'
		sidebar: 'dashboard_sidebar'
		footer: 'dashboard_footer'
		default_content: "home"
	}
	
	return $vweb.html()
}

pub fn (mut app App) dashboard_navbar() vweb.Result {

	navbar := Navbar {
		logo_path: '#'
	}
	
	return $vweb.html()
}
