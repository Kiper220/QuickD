#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texture_coordinate;

out vec2 texCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat3x2 info;
// info[0] - size of glyph.
// info[1] - texture size for textcoord.
// info[2] - position modyficator.

void main()
{
    float texPositionX = info[1][0]*texture_coordinate.x;
    float texPositionY = info[1][1]*texture_coordinate.y;
    texCoord = vec2(texPositionX, texPositionY);

    float positionX = position.x*info[0][0] + info[2][0];
    float positionY = position.y*info[0][1] + info[2][1];
    float positionZ = position.z;
    gl_Position = projection * model * vec4(positionX, positionY, positionZ, 1.0);
}