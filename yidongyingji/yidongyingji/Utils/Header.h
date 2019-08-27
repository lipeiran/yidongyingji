//
//  Header.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/16.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef Header_h
#define Header_h

#define Base_Draw_w 480.0
#define Base_Draw_h 640.0

#define Draw_x 0
#define Draw_y 0
#define Draw_w 1200
#define Draw_h 1600

#ifdef __OBJC__
#import <UIKit/UIKit.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)
NSString *const kSamplingVertexShaderC_lpr = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kSamplingFragmentShaderC_lpr = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 textureColor2 = texture2D(inputImageTexture2, vec2(textureCoordinate.x/2.0,1.0-textureCoordinate.y));
     lowp vec4 textureColor3 = texture2D(inputImageTexture2, vec2(0.5+textureCoordinate.x/2.0,1.0-textureCoordinate.y));
     gl_FragColor = textureColor * (1.0-textureColor3.r) + textureColor2;
 }
 );

NSString *const kSamplingFragmentShaderC_file_lpr = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, vec2(textureCoordinate.x,1.0-textureCoordinate.y));
     lowp vec4 textureColor2 = texture2D(inputImageTexture2, vec2(textureCoordinate.x/2.0,textureCoordinate.y));
     lowp vec4 textureColor3 = texture2D(inputImageTexture2, vec2(0.5+textureCoordinate.x/2.0,textureCoordinate.y));
     gl_FragColor = textureColor * (1.0-textureColor3.r) + textureColor2;
 }
 );

NSString *const kPassThroughFragmentShaderC_lpr = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, vec2(textureCoordinate.x,1.0-textureCoordinate.y));
 }
 );

NSString *const kColorSwizzlingFragmentShaderC_lpr = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
 );


static const GLfloat imageVertices_lpr[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat textureCoordinates_lpr[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};
#endif

#endif /* Header_h */
