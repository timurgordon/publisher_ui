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
import freeflowuniverse.crystallib.publisher2 { Publisher, User }
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

fn new_app() &App {
    mut publisher := publisher2.get() or { panic(err) }
	mut app := &App {
		publisher: publisher
	}
		
    // makes all static files available.
    app.mount_static_folder_at(os.resource_abs_path('.'), '/')
    return app
}

struct App {
	vweb.Context
mut:
	channel chan Message
	user User
	email string
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
	lock app.publisher {
		app.publisher.site_add("zanzibar", .book)
		site_path := Path {
			path: '/Users/timurgordon/code/github/ourworld-tsc/ourworld_books/docs/zanzibar'
		}
		app.publisher.sites["zanzibar"].path = site_path
	}
	println('runnin')
	vweb.run(app, port)
}

pub fn (mut app App) index() vweb.Result {
	return $vweb.html()
}

pub fn (mut app App) await_authentication() vweb.Result {
	return app.html(
		'<span>Awaiting authentication</span>'
	)
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

	home_route := Route {
		route: 'home'
		//redirect: 'login'
		//access_check: home_access
	}


	dashboard_router := Router {
		active: home_route
		output: 'dashboard-container'
		routes: [
			home_route
		]
	}
	
	dashboard := Dashboard {
		logo_path: '#'
		navbar: 'dashboard_navbar'
		sidebar: 'dashboard_sidebar'
		footer: 'dashboard_footer'
		router: dashboard_router
	}

	app.dashboard = dashboard
	
	return $vweb.html()
}

pub fn (mut app App) dashboard_navbar() vweb.Result {

	navbar := Navbar {
		logo_path: '#'
	}
	
	return $vweb.html()
}

pub fn (mut app App) dashboard_footer() vweb.Result {
	footer := Footer {
		links: ['link']
	}
	return $vweb.html()
}