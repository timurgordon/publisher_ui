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
import freeflowuniverse.crystallib.publisher2 { Publisher, User, ACE, ACL, Authentication, Email }
import freeflowuniverse.crystallib.pathlib { Path }

const (
	port = 8000
)

struct Message {
	event string
	data string
}

fn run_publisher(ch chan Message) {
	mut buf := Message{}
	for {
		buf = <- ch
		println(buf)
	}
}

// fn main() {
// 	ch := chan Message{}
// 	go run_server(ch)
// 	go run_publisher(ch)

// 	for{}
// }

fn new_app(ch chan Message) &App {
    mut publisher := publisher2.get() or { panic(err) }
	mut app := &App {
		publisher: publisher
		channel: ch
	}
		
    // makes all static files available.
    app.mount_static_folder_at(os.resource_abs_path('.'), '/')
    return app
}

struct App {
	vweb.Context
mut:
	channel shared chan Message
	user User
	email string
	publisher Publisher
	dashboard Dashboard
	authenticators shared map[string]Auth
	home Home
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

fn new_publisher() Publisher {
	mut publisher := publisher2.get() or {
		panic("can'tget publisher")
	}
	
	publisher.site_add("zanzibar", .book)
	site_path := Path {
		path: '/Users/timurgordon/code/github/ourworld-tsc/ourworld_books/docs/zanzibar'
	}
	publisher.sites["zanzibar"].path = site_path

	user_timur := User {
		name: 'timur@threefold.io'
		emails: [
			Email { address: 'timur@threefold.io', authenticated: false }
		]
	}

	site_ace := ACE {
		users: [&user_timur]
		right: .write
	}

	site_acl := ACL {
		name: 'zanzibar_acl'
		entries: [site_ace]
	}

	site_auth := Authentication {
		email_required: true			
		email_authenticated: false 
		tfconnect: false		
		kyc: false			
		acl: [&site_acl]
	}

	publisher.sites["zanzibar"].authentication = site_auth
	publisher.users['timur@threefold.io'] = user_timur
	return publisher
}

fn listener(ch chan Message) {
	mut msg := Message{}
	for {
		msg = <- ch
		println(msg)
	}
}

fn main() {
	ch := chan Message{}
	go listener(ch)
	mut app := new_app(ch)
	lock app.channel {
		app.channel = ch
	}
	
	go vweb.run(app, port) 
	for {

	}
}

pub fn (mut app App) index() vweb.Result {

	return $vweb.html()
}

// pub fn (mut app App) new_site() vweb.Result


// from vweb_example.v
pub fn (mut app App) create_cookie() vweb.Result {
	token := make_token(app.user)
	app.set_cookie(name: 'token', value: token)
	return app.text('Response Headers\n$app.header')
}

