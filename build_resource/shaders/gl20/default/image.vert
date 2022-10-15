#version 110

attribute vec3 position;
attribute vec2 texture_coordinate;

varying vec2 texCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 size;

void main()
{
    texCoord = texture_coordinate;
    gl_Position = projection * model * vec4(position.x*size.x, position.y*size.y, position.z*size.z, 1.0);
}