shader_type spatial;

uniform vec3 albedo : source_color = vec3(1.0);

void vertex() {
	// Called for every vertex
}

void fragment() {
	// Called for every pixel
	ALBEDO = albedo;
}
