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


// ['/dashboard/:route']
// pub fn (mut app App) dashboard(route string) vweb.Result {
// 	return app.dashboard
// }

// // returns dashboard layout and current page
// ['/dashboard/:route']
// pub fn (mut app App) dashboard_router(route string) vweb.Result {
// 	println(app.req)

// 	return $vweb.html()
// }

['/dashboard']
pub fn (mut app App) dashboard() vweb.Result {
	url := app.get_header('Hx-Current-Url')
	split_url := url.split('/')
	mut current_url := 'dashboard/home'
	if url.contains('dashboard/') {
		current_url = url.split('dashboard/')[1]
	} else {
		app.add_header('Hx-Push', 'dashboard')
	}

	dashboard := Dashboard {
		logo_path: '#'
		navbar: '/dashboard/navbar'
		sidebar: '/dashboard/sidebar'
		router: '/home'
		output: 'dashboard-container'
	}

	// app.add_header('HX-Push', '/dashboard/home')

	return $vweb.html()
}

['/dashboard/navbar']
pub fn (mut app App) dashboard_navbar() vweb.Result {

	navbar := Navbar {
		logo_path: '#'
		username: app.user.name
	}
	
	return $vweb.html()
}

['/dashboard/sidebar']
pub fn (mut app App) dashboard_sidebar() vweb.Result {

	home_action := Action {
		label: "Home",
		icon: "#",
		route: "/dashboard/home",
		target: "#dashboard-container"
	}

	kanban_action := Action {
		label: "Sites",
		icon: "#",
		route: "/dashboard/sites",
		target: "#dashboard-container"
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