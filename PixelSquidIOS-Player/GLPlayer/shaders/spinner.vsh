attribute vec2 position;

uniform mat4 matrix;

varying vec2 fragmentCoordinates;
varying vec2 fragmentTextureCoordinates;
varying vec2 fragmentAlphaCoordinates;

const vec2 textureScale = vec2(0.5, 1.0);

void main()
{
  vec2 scaledPosition = position * textureScale;

  gl_Position = matrix * vec4(position, 1.0, 1.0);
  fragmentCoordinates = position;
  fragmentTextureCoordinates = scaledPosition;
  fragmentAlphaCoordinates = scaledPosition + vec2(0.5, 0.0);
}
