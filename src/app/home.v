
// entities
struct Home {
    title string
    description string
	content string
}

// services
fn load_home() Home ? {
    return home
}

// routes
['/home']
pub fn (mut app App) home() vweb.Result {
    return $vweb.html()
}

