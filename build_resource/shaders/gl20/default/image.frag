#version 110

varying vec2 texCoord;

uniform sampler2D tex;

void main()
{
    gl_FragColor = vec4(texture2D(tex, texCoord));
}
