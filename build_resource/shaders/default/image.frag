#version 410 core

in vec2 texCoord;
out vec4 color;

uniform sampler2D tex;

void main()
{
    //color = vec4(TexCoord,0,1);
    color = texture(tex, texCoord);
}