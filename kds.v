module main

struct AAA{
mut:
	items []BBB
	items_keys map[string]int
}

struct BBB{
mut:
	name string
}

fn (mut container AAA ) get()&BBB {
	mut w:= container.items["x"]
	return w
}

fn main(){

	mut a:= AAA{}
	a.items["x"] = BBB{name:"some1"}
	a.items["y"] = BBB{name:"some2"}



	println(a)


}