attribute vec2 position;

uniform mat4 matrix;

varying vec2 fragmentTextureCoordinates;

void main()
{
  gl_Position = matrix * vec4(position, 1.0, 1.0);
  fragmentTextureCoordinates = position;
}