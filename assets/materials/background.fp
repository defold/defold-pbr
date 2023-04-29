varying highp vec3 var_position;
uniform lowp samplerCube tex0;

const float gamma = 2.2;

vec3 fromLinear(vec3 linearIn)
{
    return pow(linearIn, vec3(1.0 / gamma));
}

/*
const float gamma = 2.2;
vec3 hdrColor = texture(hdrBuffer, TexCoords).rgb;

// exposure tone mapping
vec3 mapped = vec3(1.0) - exp(-hdrColor * exposure);
// gamma correction 
mapped = pow(mapped, vec3(1.0 / gamma));

FragColor = vec4(mapped, 1.0);
*/

vec3 exposure(vec3 hdrIn, float expvalue)
{
    vec3 mapped = vec3(1.0) - exp(-hdrIn * expvalue);
    return pow(mapped, vec3(1.0 / gamma));
}

void main()
{
    vec4 color = textureLod(tex0, var_position.xyz, 5.0);
    gl_FragColor = vec4(fromLinear(color.rgb),1.0);
    gl_FragColor = vec4(exposure(color.rgb, 0.5), 1.0);
}

