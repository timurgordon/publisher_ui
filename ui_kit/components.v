module ui_kit
import vweb
import htmx { HTMX }

pub struct Navbar {
pub mut:
	logo_path string
	username string
}

pub struct Footer {
pub:
	links []string
	template string = "./dashboard.html"
}

pub struct Button {
pub: 
	label string
	icon string
	hx HTMX
}