module main

import vweb
import ui_kit
import base64

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
	token := app.get_cookie('token') or { '' }
	mut home := app.home
	username := t
	accesible_site :=
	sites := app.publisher.sites.values.filter(user.get_access(it.auth) == .read)
	access := home.gatekeeper(token) 
	if access == 'access' {
		println("accessing")
		return $vweb.html()
	}
	println("lgin")
	return app.login()
}

pub fn (mut app App) sites_filterbar() vweb.Result {
	return $vweb.html()
}

['/site_card/:name']
pub fn (mut app App) sites_card(name string) vweb.Result {
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
