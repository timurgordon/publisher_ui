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
import freeflowuniverse.crystallib.publisher2 { Publisher, User, ACE, ACL, Authentication, Email, Right, Access }
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

pub fn (mut app App) before_request() {
	token := app.get_cookie('token') or { '' }
	app.user = get_user(token) or { User{} }
	if app.req.url.starts_with('/sites/') {
		sitename := app.req.url.split('/')[2]
		mut access := Access{}
		rlock app.publisher {
			access = app.publisher.get_access(app.user.name, sitename)
		}
		if access.right == .read || access.right == .write {
			if access.status == .email_required {
				if app.user.emails.len == 0 {
					app.attempted_url = app.req.url
					app.redirect('/dashboard/login')
				}
			}
			if access.status == .auth_required {
				if ! app.user.emails.any(it.authenticated) {
					app.redirect('/dashboard/auth_verify/$token')
				}
			}
		}
	}
}

fn new_app() &App {
	mut app := &App {}
		
	// app.serve_static('/static/sites', 'static/sites/index.html')
    app.mount_static_folder_at(os.resource_abs_path('./static'), '/static')
    // app.mount_static_folder_at(os.resource_abs_path('./static'), '/static')
    return app
}

struct App {
	vweb.Context
mut:
	channel chan Message
	user User
	email string
	attempted_url string
	publisher shared Publisher
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

fn main() {
	mut app := new_app()
	mut publisher := publisher2.get() or { panic(err) }

	user_timur := publisher.user_add('timur@threefold.io')

	// new site zanzibar that is accessible to with email 
	sitename1 := 'zanzibar'
	site1 := publisher.site_add(sitename1, .book)
	site_path1 := Path {
		path: '/Users/timurgordon/code/github/ourworld-tsc/ourworld_books/docs/zanzibar'
	}
	publisher.sites["zanzibar"].path = site_path1
	publisher.sites["zanzibar"].authentication.email_required = true
	publisher.sites["zanzibar"].authentication.email_authenticated = false
	if ! os.exists('sites/$sitename1') {
		os.symlink(site_path1.path, 'sites/$sitename1')?
	}

	// new site zanzibar feasibility that requires authenticated email
	sitename2 := 'ourworld_zanzibar_feasibility'
	site2 := publisher.site_add("ourworld_zanzibar_feasibility", .book)
	site_path2 := Path {
		path: '/Users/timurgordon/code/github/ourworld-tsc/ourworld_books/docs/ourworld_zanzibar_feasibility'
	}
	publisher.sites["ourworld_zanzibar_feasibility"].path = site_path2
	publisher.sites["ourworld_zanzibar_feasibility"].authentication.email_required = true
	publisher.sites["ourworld_zanzibar_feasibility"].authentication.email_authenticated = true
	if ! os.exists('sites/$sitename2') {
		os.symlink(site_path1.path, 'sites/$sitename2')?
	}

	// user_timur := publisher.user_add('timur@threefold.io')
	// publisher.users['timur@threefold.io'].emails = [Email { address: 'timur@threefold.io', authenticated: false }]


	// // site_ace := ACE {
	// // 	users: [user_timur]
	// // 	right: .write
	// // }

	// mut site_acl := publisher.acl_add('zanzibar_acl')
	// //publisher.acls["zanzibar_acl"].entries = [site_ace]

	// site_ace := site_acl.ace_add(.write)
	
	// auth := site.auth_add(true, false, site_acl)
	// // auth := Authentication {
	// // 	email_required: true
	// // 	email_authenticated: false
	// // 	acl: [site_acl]
	// // }

	//publisher.sites["zanzibar"].authentication = auth

	lock app.publisher{
		app.publisher = publisher
	}
	vweb.run(app, port)
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

