
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.12, 0.42, 1.0, 1.0);

uniform vec2 glow_center = vec2(0.5, 0.62);

uniform float glow_radius = 0.75;

uniform float glow_power = 2.0;

uniform float intensity = 0.8;

void fragment() {
    vec2 uv = UV - glow_center;

    uv.x *= 16.0 / 9.0;

    float d = length(uv);

    float glow = 1.0 - smoothstep(
        0.0,
        glow_radius,
        d
    );

    glow = pow(glow, glow_power);

    COLOR = vec4(
        glow_color.rgb,
        glow * intensity
    );
}
