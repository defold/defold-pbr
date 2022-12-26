varying mediump vec2 var_texcoord0;
varying mediump vec3 var_normal;
varying mediump vec3 var_position;
varying mediump vec3 var_camera;

uniform lowp samplerCube tex0;

uniform lowp vec4 u_roughness;

vec3 fromLinear(vec3 linearIn)
{
    return pow(linearIn, vec3(1.0 / 2.2));
}

vec3 Uncharted2Tonemap(vec3 color)
{
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;
    float W = 11.2;
    return ((color*(A*color+C*B)+D*E)/(color*(A*color+B)+D*F))-E/F;
}

void main()
{
    vec3 I       = normalize(var_position - var_camera.xyz);
    vec3 R       = reflect(I, normalize(var_normal));
    vec4 color   = vec4(textureLod(tex0, R, u_roughness.r).rgb, 1.0);
    gl_FragColor = vec4(fromLinear(Uncharted2Tonemap(color.rgb)), 1.0);
}

