varying highp vec3 var_position;

#include "/defold-pbr/shaders/pbr_common.glsl"
#include "/defold-pbr/shaders/pbr_input.glsl"

void main()
{
    vec4 color   = textureLod(tex_prefiltered_reflection, var_position.xyz, 5.0);
    gl_FragColor = vec4(fromLinear(color.rgb),1.0);
    gl_FragColor = vec4(exposure(color.rgb, PBR_CAMERA_EXPOSURE), 1.0);
}