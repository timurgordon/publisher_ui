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

['/dashboard/home']
pub fn (mut app App) home() vweb.Result {
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
