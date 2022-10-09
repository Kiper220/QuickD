#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texture_coordinate;

out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    TexCoord = texture_coordinate;
    gl_Position = projection * vec4(position.x, position.y, position.z, 1.0);
}