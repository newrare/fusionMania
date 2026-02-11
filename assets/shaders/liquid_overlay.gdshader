shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 50.0) = 16.0;
uniform vec2 rect_size = vec2(240.0, 240.0);
uniform float fill_percent : hint_range(0.0, 1.0) = 1.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wave_amplitude : hint_range(0.0, 20.0) = 5.0;
uniform float wave_frequency : hint_range(0.0, 20.0) = 8.0;

float rounded_box_sdf(vec2 center_pos, vec2 size, float radius) {
	vec2 q = abs(center_pos) - size + vec2(radius);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void fragment() {
	vec2 pixel_pos = UV * rect_size;
	vec2 center_pos = pixel_pos - rect_size * 0.5;
	float dist = rounded_box_sdf(center_pos, rect_size * 0.5, corner_radius);
	
	// Outside rounded rect = discard
	if (dist > 0.0) {
		discard;
	}
	
	// Calculate liquid surface with wave
	float wave = sin((UV.x * wave_frequency) + (TIME * wave_speed)) * wave_amplitude / rect_size.y;
	float liquid_surface = 1.0 - fill_percent + wave;
	
	// Above liquid surface = discard (transparent)
	if (UV.y < liquid_surface) {
		discard;
	}
	
	// Liquid effect: semi-transparent overlay with slight variation
	float depth = (UV.y - liquid_surface) / fill_percent;
	float brightness = 0.9 + depth * 0.2;
	
	vec4 color = COLOR;
	color.rgb *= brightness;
	color.a *= 0.3; // Semi-transparent to show background
	
	// Smooth edge
	float alpha = 1.0 - smoothstep(-1.0, 0.0, dist);
	color.a *= alpha;
	
	COLOR = color;
}
