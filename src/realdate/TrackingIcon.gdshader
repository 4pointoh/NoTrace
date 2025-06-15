shader_type canvas_item;

uniform float speed : hint_range(0.1, 2.0) = 0.5;
uniform float line_spawn_interval : hint_range(0.1, 0.5) = 0.25;
uniform float circle_spacing : hint_range(0.05, 0.2) = 0.1;
uniform float start_size : hint_range(0.005, 0.02) = 0.01;
uniform float end_size : hint_range(0.03, 0.5) = 0.06;
uniform vec4 circle_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform int max_lines : hint_range(3, 20) = 5;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    float effect = 0.0;
    
    // Direction vectors
    vec2 line_direction = normalize(vec2(1.0, -1.0)); // Diagonal line direction
    vec2 move_direction = normalize(vec2(1.0, 1.0));  // Movement direction
    
    // Create multiple lines
    for (int line = 0; line < max_lines; line++) {
        // Each line has its own start time
        float line_time = TIME * speed - float(line) * line_spawn_interval;
        
        // Skip if this line hasn't started yet
        if (line_time < 0.0) continue;
        
        // Wrap around for continuous effect
        line_time = mod(line_time, 2.0);
        
        // Create circles along this line
        int circle_count = int(3.0 / circle_spacing);
        
        for (int i = -circle_count; i < circle_count; i++) {
            // Base position along the diagonal line
            vec2 base_pos = vec2(0.5, 0.5) + line_direction * float(i) * circle_spacing;
            
            // Move the line over time
            vec2 circle_pos = base_pos + move_direction * line_time * 0.7;
            
            // Skip circles that are too far off screen
            if (circle_pos.x < -0.5 || circle_pos.x > 1.5 || 
                circle_pos.y < -0.5 || circle_pos.y > 1.5) continue;
            
            // Circle size grows with time/distance
            float growth = line_time / 2.0;
            float radius = mix(start_size, end_size, growth);
            
            // Check if pixel is inside this circle
            float dist = distance(UV, circle_pos);
            
            if (dist < radius) {
                float intensity = 1.0 - smoothstep(radius * 0.7, radius, dist);
                
                // Fade out older lines
                float fade = 1.0 - (line_time / 2.0);
                intensity *= fade;
                
                effect = max(effect, intensity);
            }
        }
    }
    
    COLOR = mix(base_color, base_color + circle_color, effect * circle_color.a);
}