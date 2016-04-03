uniform sampler2D texture;
uniform lowp float alpha;
varying mediump vec2 fragmentTextureCoordinates;

void main()
{
  // Assumes premultiplied
  gl_FragColor = texture2D(texture, fragmentTextureCoordinates) * alpha;
}