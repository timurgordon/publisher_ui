module ui_kit

import vweb

pub struct Dashboard {
pub mut:
	logo_path string
	navbar string
	sidebar string
	footer string
	default_content string
	template string = "./dashboard.html"
}

pub struct Navbar {
pub mut:
	logo_path string
}

pub struct Footer {
	links []string
	template string = "./dashboard.html"
}