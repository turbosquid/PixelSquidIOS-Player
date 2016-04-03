precision highp float;

attribute vec2 position;

uniform mat4 matrix;
uniform float u_radius;
uniform vec2 u_direction;

varying vec2 v_texCoord;
varying vec2 v_blurTexCoords[14];

void main()
{
  gl_Position = matrix * vec4(position, 1.0, 1.0);
  v_texCoord = position;

  for (int i = 0; i < 7; ++i) {
    float distance = u_radius / 7.0 * (7.0 - float(i));
    vec2 offset = u_direction * distance;
    v_blurTexCoords[i] = v_texCoord - offset;
    v_blurTexCoords[13-i] = v_texCoord + offset;
  }
}