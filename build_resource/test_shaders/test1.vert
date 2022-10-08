#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texture_coordinate;

out vec2 TexCoord;

void main()
{
    TexCoord = texture_coordinate;
    gl_Position = vec4(position.x, position.y, position.z, 1.0);
}