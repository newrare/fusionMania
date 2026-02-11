shader_type canvas_item;

uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wave_amplitude : hint_range(0.0, 10.0) = 3.0;
uniform float wave_frequency : hint_range(0.0, 20.0) = 8.0;

void fragment() {
	vec2 uv = UV;
	
	// Create wave effect at the top of the liquid
	float wave_offset = sin((uv.x * wave_frequency) + (TIME * wave_speed)) * (wave_amplitude / 100.0);
	
	// Apply wave only near the top edge
	float edge_distance = 1.0 - uv.y;
	float wave_strength = smoothstep(0.9, 1.0, edge_distance);
	
	vec2 distorted_uv = uv;
	distorted_uv.y += wave_offset * wave_strength;
	
	// Sample the original color
	vec4 color = COLOR;
	
	// Discard pixels above the wave
	if (distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
		discard;
	}
	
	// Add subtle brightness variation for liquid depth effect
	float depth = 1.0 - uv.y;
	color.rgb *= 0.85 + (depth * 0.3);
	
	COLOR = color;
}
