shader_type canvas_item;

uniform vec3 flashColor : source_color = vec3(1);
uniform float intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float wave : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float speed : hint_range(0.0, 5.0, 0.01) = 1.0;

uniform sampler2D dissolve_texture : source_color;
uniform float dissolve_value : hint_range(0, 1) = 0.0;
uniform float burn_size : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform vec4 burn_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);

// 🆕 Gradient mask (white = more wavy, black = less wavy)
uniform sampler2D gradient_mask : source_color;

void fragment() {
    float time = TIME * speed;

    // --- Dissolve mask ---
    float noise_val = texture(dissolve_texture, UV).r;
    float edge = burn_size * 0.5;
    float dissolve_alpha = smoothstep(dissolve_value - edge, dissolve_value + edge, noise_val);
    float border = smoothstep(dissolve_value, dissolve_value + burn_size, noise_val);

    // --- Sample gradient mask ---
    float grad = texture(gradient_mask, UV).r; // 0.0 (black) → 1.0 (white)

    // --- Wave distortion (scaled by gradient) ---
    vec2 uv = UV;
	
	uv += wave * grad * vec2(
	    sin(UV.y * 50.0 + time * 5.0),
	    cos(UV.x * 50.0 + time * 5.0)
	) * 0.02;


    // --- Sample the sprite texture ---
    vec4 base_color = texture(TEXTURE, uv);

    // --- Combine alpha ---
    float final_alpha = base_color.a * dissolve_alpha;

    // --- Mix burn border and base color ---
    vec3 final_rgb = mix(burn_color.rgb, base_color.rgb, border);

    // --- Apply flash overlay ---
    final_rgb = mix(final_rgb, flashColor, intensity);

    // --- Output ---
    COLOR = vec4(final_rgb, final_alpha);
}
