module ui_kit

import freeflowuniverse.crystallib.publisher2 { User }
import freeflowuniverse.crystallib.pathlib { Path }
import vweb
import htmx { HTMX }
import os

pub interface Component {
	template string // path to html template
}

// pub fn (comp Component) render() string {
// 	current_url:= '/home'
// 	return $tmpl('')
// }

// pub struct Router {
// 	main Route
// 	routes []Route
// 	output string 
// pub mut:
// 	active Route
// }

// a gatekeeper function for routes
// takes a user, returns whether they have access
type Routekeeper = fn (user User) bool

pub struct Route {
pub:
	route string
	redirect string
	access_check Routekeeper
}

