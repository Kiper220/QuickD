#version 410 core
out vec4 color;
in vec2 texCoord;

uniform vec3 texture_pos;
uniform sampler2D tex;

void main()
{
    vec4 sampled = vec4(1,1,1, texture(tex, vec2(texCoord.x + texture_pos.x, texCoord.y + texture_pos.y)).r);
    //color = vec4(0,vec2(texCoord.x + texture_pos.x, texCoord.y + texture_pos.y),0.5);
    color = sampled;
}