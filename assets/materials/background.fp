varying highp vec3 var_position;
uniform lowp samplerCube tex0;

uniform lowp vec4 u_pbr_scene_params;

#include "/defold-pbr/shaders/pbr_common.glsl"

void main()
{
    vec4 color = textureLod(tex0, var_position.xyz, 5.0);
    gl_FragColor = vec4(fromLinear(color.rgb),1.0);
    gl_FragColor = vec4(exposure(color.rgb, u_pbr_scene_params.z), 1.0);
}

