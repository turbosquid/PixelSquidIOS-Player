//  PixelSquidExample
//
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

attribute vec2 position;

uniform mat4 matrix;
uniform bool u_flattened;

varying vec2 fragmentAlphaCoordinates;

const vec2 textureScale = vec2(0.5, 1.0);
const vec2 textureOffset = vec2(0.5, 0.0);

void main()
{
  gl_Position = matrix * vec4(position, 1.0, 1.0);
  if (u_flattened) {
    fragmentAlphaCoordinates = position;
  }
  else {
    fragmentAlphaCoordinates = position * textureScale + textureOffset;
  }
}