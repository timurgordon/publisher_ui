module main

import vweb
import os

struct Home {
	name string
}

pub fn (mut app App) home() vweb.Result {

	if app.get_header('Hx-Request') != 'true' {
		return app.index()
	}
	
	content := os.read_file('src/content/home/home.md') or { 
		panic("Failed to read home content: $error") 
	}

	return $vweb.html()
}
