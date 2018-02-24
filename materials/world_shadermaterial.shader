shader_type spatial;
render_mode unshaded,cull_front;

varying smooth vec3 our_color;
void vertex() {
    our_color = COLOR.rgb;
}

void fragment() {
    ALBEDO = our_color;
}