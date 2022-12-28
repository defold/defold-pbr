varying highp vec3 var_position;
uniform lowp samplerCube tex0;

vec3 fromLinear(vec3 linearIn)
{
    return pow(linearIn, vec3(1.0 / 2.2));
}

void main()
{
    vec4 color = textureLod(tex0, var_position.xyz, 5.0);
    gl_FragColor = vec4(fromLinear(color.rgb),1.0);
}

