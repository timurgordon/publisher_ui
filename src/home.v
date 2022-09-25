module main

import vweb
import ui_kit
import encoding.base64
import freeflowuniverse.crystallib.publisher2 { User, Site }
import json

type Route = fn() vweb.Result

struct Home {
	name string
}

pub fn (mut home Home) gatekeeper(token string) string {
	if token == '' {
		return 'no_access'
	}
	if auth_verify(token) {
		return 'access'
	}
	return 'no_access'
}

pub fn (mut app App) home() vweb.Result {
	println("home $app.publisher")
	token := app.get_cookie('token') or { '' }
	mut home := app.home
	access := home.gatekeeper(token) 
	lock app.channel {
		println(app)
		app.channel <- Message {
			event: "init"
		}
	}
	if access == 'access' {
		username := get_username(token)
		mut accessible_sites := map[string]Site
		// rlock app.publisher {
			user := app.publisher.users[username]
			accessible_sites = user.get_sites(app.publisher.sites)
			//sites := app.publisher.sites.values.filter(user.get_access(it.auth) == .read)
		// }
		return $vweb.html()
	}
	return app.login()
}

pub fn (mut app App) sites_filterbar() vweb.Result {
	return $vweb.html()
}

['/site_card/:name']
pub fn (mut app App) sites_card(name string) vweb.Result {
	mut site := Site {}
	// rlock app.publisher{
		site = app.publisher.sites[name]
	// }
	return $vweb.html()
}


// pub fn (mut home Home) render() vweb.Result {
// 	// app.user.emails = ["email"]
// 	token := app.get_header('token')

// 	if home_access(app.user, token) {
// 		return $vweb.html()
// 	} else {
// 		return app.login()
// 	}
// }
