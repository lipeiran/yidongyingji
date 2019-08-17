//
//  LPRGPUImageMovieWriter.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/17.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageContext.h"
#import <AVFoundation/AVFoundation.h>
#import "GLProgram.hpp"
#import "utils.hpp"
#import "LPRGPUImageFilter.h"

@interface LPRGPUImageMovieWriter : NSObject
{
    LPRGPUImageFilter *imageFilter;
}
@property(readonly, nonatomic) CGSize sizeInPixels;

// Initialization and teardown
- (void)commonInit;

// Managing the data FBO
- (void)createDataFBO;
- (void)destroyDataFBO;

// 开始导出
- (void)startRecording;

// 结束导出
- (void)stopRecording;

@end

