//
//  Shader.fsh
//  PixelSquidIOS-Player
//
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
