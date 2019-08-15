//
//  LPRGPUImageView.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageContext.h"
#import <AVFoundation/AVFoundation.h>
#import "GLProgram.hpp"
#import "utils.hpp"
#import "LPRGPUImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRGPUImageView : UIView
{
    LPRGPUImageFilter *imageFilter;
    LPRGPUImageFilter *imageFilter2;
    LPRGPUImageFilter *imageFilter3;

}

@property(readonly, nonatomic) CGSize sizeInPixels;

// Initialization and teardown
- (void)commonInit;

// Managing the display FBOs
- (void)createDisplayFramebuffer;
- (void)destroyDisplayFramebuffer;

- (void)play;
- (void)pause;
- (void)resume;
- (void)stop;
- (void)seekToPercent:(CGFloat)percent;

@end

NS_ASSUME_NONNULL_END
