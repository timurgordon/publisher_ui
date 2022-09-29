module main

import vweb
import os
import freeflowuniverse.crystallib.pathlib { Path }
import freeflowuniverse.crystallib.publisher2 { Site, AccessLog, Access }
import ui_kit { Action, ActionType }
import time

// gets the map of sites accessible by user
// gets and displays site cards for all accesible sites
// returns the sites page in dashboard
['/dashboard/sites']
pub fn (mut app App) sites() vweb.Result {
	if app.get_header('Hx-Request') != 'true' {
		return app.index()
	}
	token := app.get_cookie('token') or { '' }
	mut home := app.home
	mut accessible_sites := map[string]Site
	rlock app.publisher {
		user := app.publisher.users[app.user.name]
		accessible_sites = app.publisher.get_sites_accessible(app.user.name)
		//sites := app.publisher.sites.values.filter(user.get_access(it.auth) == .read)
	}
	return $vweb.html()
}

// returns the 
['/sites/preview/:site_name']
pub fn (mut app App) sites_preview(sitename string) vweb.Result {
	if app.get_header('Hx-Request') != 'true' {
		return app.index()
	}
	token := app.get_cookie('token') or { '' }
	mut home := app.home
	mut accessible_sites := map[string]Site
	rlock app.publisher {
		user := app.publisher.users[app.user.name]
		accessible_sites = app.publisher.get_sites_accessible(app.user.name)
		//sites := app.publisher.sites.values.filter(user.get_access(it.auth) == .read)
	}
	return $vweb.html()
}

// checks if user has right to access site
// if so responds with site asset requests and injects logger htmx
['/sites/:path...']
pub fn (mut app App) site(path string) vweb.Result {
	
	// sitename := path.split('/')[1]
	// site := Site {}
	// rlock {
	// 	site = app.publisher.sites[sitename]
	// }
	// user_right := app.publisher.user.get_right(site.authentication)
	// if !(user_right == .read || user_right == .write) {
	// 	app.add_header()
	// }

	// TODO: os.read_file('mermaid.js.map') doesn't work
	if path.ends_with('.map') {
		return app.ok('')
	} 
	mut response := os.read_file('sites/$path') or { panic("fail: $path, $error") }
	app.set_content_type(app.req.header.get(.content_type) or { '' })
	
	// injects htmx script to log access to site pages
	if app.req.url.ends_with('.html') {
		mut split_resp := response.split('<body>')
		split_resp[1] = '\n<script src="/static/htmx.min.js"></script>' + split_resp[1]
		response = split_resp.join('<body>')
		response = '<div hx-trigger="every 5s" hx-get="/site_log$app.req.url" hx-swap="none" class="m-20"> $response </div>'
	}
	
	return app.ok(response)
}

// receives pings every 5 seconds from site pages,
// adds logs to the site object on user, timestamp and page
['/site_log/:path...']
pub fn (mut app App) site_log(path string) vweb.Result {
	sitename := path.split('/')[1]

	log := AccessLog {
		user: app.publisher.users[app.user.name]
		path: Path { path: path }
		time: time.now()
	}

	lock app.publisher {
		app.publisher.sites[sitename].logs << log
	}
	return app.text('')
}

pub fn (mut app App) sites_filterbar() vweb.Result {
	return $vweb.html()
}

['/site_card/:name']
pub fn (mut app App) sites_card(name string) vweb.Result {
	mut site := Site {}
	mut access := Access {}

	rlock app.publisher {
		site = app.publisher.sites[name]
		access = app.publisher.get_access(app.user.name, name)
	}
	
	mut preview_site := Action {
		label: 'Preview Site'
		route: '/dashboard/sites/preview/@site.name'
		target: '#dashboard-container'
	}

	mut open_site := Action {
		label: 'Open Site'
		route: '/sites/@site.name/index.html'
		target: '_blank'
	}

	if access.status == .email_required || access.status == .auth_required {
		preview_site.route = '/login/$name/$access.status'
		open_site.route = '/login/$name/$access.status'
		open_site.target = '#dashboard-container'
	}

	println("debugssz: $access, $preview_site")

	return $vweb.html()
}