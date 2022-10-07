module main

import vweb
import os
import freeflowuniverse.crystallib.pathlib { Path }
import freeflowuniverse.crystallib.publisher2 { Site, AccessLog, Access }
import ui_kit { Action, ActionType }
import time
import net.html

// gets ssites that 
pub fn (mut app App) site_get_access(name string) Access {
	cookie := app.get_cookie(name) or { '' }
	return get_access(cookie, app.user.name) or {
		mut access := Access{}
		rlock app.publisher {
			access = app.publisher.get_access(app.user, name)
		}
		// app.create_access_cookie(name, access)
		return access
	}
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

fn (mut app App) get_site(sitename string) Site {
	mut site := Site{}
	rlock app.publisher {
		site = app.publisher.sites[sitename]
	}
	return site
}

fn (mut app App) get_access(sitename string) Access {
	mut access := Access{}
	rlock app.publisher {
		access = app.publisher.get_access(app.user, sitename)
	}
	return access
}

