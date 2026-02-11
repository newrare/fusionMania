shader_type canvas_item;

uniform vec4 liquid_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float wave_amplitude : hint_range(0.0, 30.0) = 8.0;
uniform float wave_frequency : hint_range(1.0, 30.0) = 10.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 3.0;
uniform float surface_height : hint_range(0.0, 1.0) = 0.0;  // 0 = full, 1 = empty
uniform float corner_radius : hint_range(0.0, 50.0) = 20.0;
uniform vec2 rect_size = vec2(240.0, 240.0);

// SDF for rounded rectangle
float rounded_box_sdf(vec2 center, vec2 size, float radius) {
    return length(max(abs(center) - size + radius, 0.0)) - radius;
}

void fragment() {
    vec2 uv = UV;
    
    // Calculate pixel position
    vec2 pixel_pos = uv * rect_size;
    vec2 center = pixel_pos - rect_size * 0.5;
    vec2 half_size = rect_size * 0.5;
    
    // Check if pixel is inside rounded rectangle
    float dist = rounded_box_sdf(center, half_size, corner_radius);
    
    // Discard pixels outside the rounded rectangle
    if (dist > 0.0) {
        discard;
    }
    
    // Calculate wave at this x position
    float wave = sin(uv.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
    wave += sin(uv.x * wave_frequency * 0.5 - TIME * wave_speed * 0.7) * wave_amplitude * 0.5;
    
    // Convert wave to UV space (assuming 240px height)
    float wave_uv = wave / 240.0;
    
    // Surface line position (where liquid starts)
    float surface = surface_height + wave_uv;
    
    // If we're below the surface (uv.y > surface), show liquid
    if (uv.y > surface) {
        // Gradient: lighter near surface, darker at bottom
        float depth = (uv.y - surface) / (1.0 - surface);
        vec4 deep_color = liquid_color * 0.7;
        COLOR = mix(liquid_color, deep_color, depth * 0.3);
        COLOR.a = 1.0;
    } else {
        // Above surface: transparent
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
