//
//  Shader.fsh
//  PixelSquidExample
//
//  Created by Mark Kurt on 3/23/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
