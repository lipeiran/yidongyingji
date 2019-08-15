//
//  GPUImageMovie.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/7.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CFString.h>
#import <CoreVideo/CoreVideo.h>

#include "GPUImageContext.h"
#import "OpenGLES2DTools.h"
#include "GLProgram.hpp"
#import "LPRGPUImageFrameBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageMovie : NSObject
{
    
}

@property (readwrite, retain) AVPlayerItem *playerItem;
@property (nonatomic, retain) LPRGPUImageFrameBuffer *outputFramebuffer;
@property (nonatomic, assign) int pts;
@property (nonatomic, assign) BOOL data_ready;

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem;

- (void)yuvConversionSetup;

- (void)startProcessing;

- (void)endProcessing;

- (void)cancelProcessing;

- (BOOL)copyNextFrame;

- (void)processPtsFrameBuffer:(int)fr;

@end

NS_ASSUME_NONNULL_END
