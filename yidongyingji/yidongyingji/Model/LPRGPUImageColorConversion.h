//
//  LPRGPUImageColorConversion.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/7.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef LPRGPUImageColorConversion_h
#define LPRGPUImageColorConversion_h
#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/EAGL.h>

extern GLfloat *kColorConversion601;
extern GLfloat *kColorConversion601FullRange;
extern GLfloat *kColorConversion709;
extern NSString *const kGPUImageYUVFullRangeConversionForLAFragmentShaderString;


#endif /* LPRGPUImageColorConversion_h */
