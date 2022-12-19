varying mediump vec2 var_texcoord0;
uniform lowp sampler2D tex0;

void main()
{
    vec4 color = texture2D(tex0, vec2(var_texcoord0.s, 1 - var_texcoord0.t));
    gl_FragColor = vec4(color.rgb, 1.0);
}

