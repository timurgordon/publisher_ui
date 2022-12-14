module ui_kit

import vweb

pub type MenuItem = Dropdown | Action 
pub type Menu = []MenuItem 

pub struct Sidebar {
	pub:
	menu   []Action
	bottom_menu Menu
}

type HTMX_fn = fn () vweb.Result

pub struct Action {
	pub:
	label string
	icon string
	route string
	swap string
	trigger string = "click"
}

pub struct Dropdown {
	pub:
	label string
	icon string
	menu []MenuItem 
}