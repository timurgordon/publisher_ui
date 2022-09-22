module ui_kit

import freeflowuniverse.crystallib.publisher2 { User }
import vweb
import os

pub interface Component {
	route Route
	template string
	has_access (User)bool
mut: 
	router Router
}

pub struct Router {
	main Route
	routes []Route
	output string 
pub mut:
	active Route
}

// a gatekeeper function for routes
// takes a user, returns whether they have access
type Routekeeper = fn (user User) bool

pub struct Route {
pub:
	route string
	redirect string
	access_check Routekeeper
}