uniform sampler2D texture;
varying mediump vec2 fragmentAlphaCoordinates;

const mediump float alphaThreshold = 10.0 / 255.0;
const mediump float minZ = -256.0;
const mediump float maxZ = 256.0;
const mediump float zLength = (maxZ - minZ) / 255.0;
const mediump float zOffset = (minZ + 1.0) / 255.0;

void main()
{

  lowp vec4 alpha = texture2D(texture, fragmentAlphaCoordinates);

  if (alpha.r < alphaThreshold) {
    // discard fragment so that it doesn't overwrite the destination alpha
    discard;
  }
  else {
    // write the z coordinate into the alpha channel
    highp float z = gl_FragCoord.z * zLength + zOffset;

    gl_FragColor = vec4(0.0, 0.0, 0.0, z);
  }
}