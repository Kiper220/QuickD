#version 110

varying vec2 texCoord;

uniform vec2 texture_pos;
uniform sampler2D tex;

void main()
{
    //gl_FragColor = vec4(1,vec2(texCoord.x, texCoord.y),1);
    vec4 sampled = vec4(0,0,0, texture2D(tex, vec2(texCoord.x, texCoord.y))[0]);
    gl_FragColor = sampled;
}