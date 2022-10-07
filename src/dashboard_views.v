module main

import net.smtp
import htmx { HTMX }
import vweb
import vweb.sse
import time { Time }
import rand { ulid }
import os
import v.ast
import ui_kit { Action, Button, Component, Dashboard, Navbar, Sidebar Footer}
import crypto.rand as crypto_rand
import sqlite
import freeflowuniverse.crystallib.publisher2 { Publisher, User, ACE, ACL, Authentication, Email }
import freeflowuniverse.crystallib.pathlib { Path }


// router to catch and redirect dashboard routes
['/dashboard/:route...']
pub fn (mut app App) dashboard_(route string) vweb.Result {
	return app.dashboard()
}

// returns dashboard with child page according to route
pub fn (mut app App) dashboard() vweb.Result {
	url := app.get_header('Hx-Current-Url')
	mut current_url := '/home'
	if app.req.url.contains('dashboard/') {
		current_url = app.req.url.all_after('dashboard')
	} else {
		app.add_header('Hx-Push', 'dashboard')
	}

	navbar := Navbar {
		logo_path: '#'
		username: app.user.name
	}

	dashboard := Dashboard {
		logo_path: '#'
		navbar: navbar
		sidebar: '/dashboard_sidebar'
	}

	// app.add_header('HX-Push', '/dashboard/home')
	return app.html(dashboard.render())
}

pub fn (mut app App) dashboard_sidebar() vweb.Result {
	home_btn := Button {
		label: "Home",
		icon: "#",
		hx: HTMX {
			get: "/home",
			target: "#dashboard-container"
		}
	}

	sites_btn := Button {
		label: "Sites",
		icon: "#",
		hx: HTMX {
			get: "/sites",
			target: "#dashboard-container"
		}
	}

	sidebar := Sidebar {
		menu: [
			home_btn,
			sites_btn
		]
	}
	return $vweb.html()
}