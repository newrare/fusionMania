shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 50.0) = 16.0;
uniform vec2 rect_size = vec2(240.0, 240.0);
uniform vec4 bg_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);

float rounded_box_sdf(vec2 center_pos, vec2 size, float radius) {
	vec2 q = abs(center_pos) - size + vec2(radius);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void fragment() {
	vec2 pixel_pos = UV * rect_size;
	vec2 center_pos = pixel_pos - rect_size * 0.5;
	float dist = rounded_box_sdf(center_pos, rect_size * 0.5, corner_radius);
	
	if (dist > 0.0) {
		discard;
	}
	
	// Use the uniform color instead of COLOR
	vec4 color = bg_color;
	
	// Smooth antialiased edge
	float alpha = 1.0 - smoothstep(-1.0, 0.0, dist);
	color.a *= alpha;
	
	COLOR = color;
}
