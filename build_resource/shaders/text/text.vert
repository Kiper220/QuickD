#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texture_coordinate;

out vec2 texCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 size;
uniform vec3 texSize;
uniform vec2 mod;

void main()
{
    texCoord = vec2((texSize.x)*texture_coordinate.x, (texSize.y)*texture_coordinate.y);
    mat4 mSize;
    gl_Position = projection * model * vec4(position.x*size.x + mod.x, position.y*size.y, position.z*size.z, 1.0);
}