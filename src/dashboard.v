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