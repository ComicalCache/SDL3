package data

@(private)
r :: .6
@(private)
lambda :: 0.8660254

Vertex :: struct {
	x: f32,
	y: f32,
	r: f32,
	g: f32,
	b: f32,
	a: f32,
}

VERTICES: [3]Vertex = {
	Vertex{x = 0, y = r, r = 1, g = 0, b = 0, a = 1},
	Vertex{x = -lambda * r, y = -.5 * r, r = 0, g = 1, b = 0, a = 1},
	Vertex{x = lambda * r, y = -.5 * r, r = 0, g = 0, b = 1, a = 1},
}
