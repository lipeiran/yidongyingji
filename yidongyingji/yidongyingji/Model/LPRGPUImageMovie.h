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

#include "LPRGPUImageContext.h"
#include "GLProgram.hpp"
#import "LPRGPUImageFrameBuffer.h"
#import "Header.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRGPUImageMovie : NSObject
{
    
}

@property (readwrite, retain) AVAsset *asset;
@property (readwrite, retain) AVPlayerItem *playerItem;
@property (nonatomic, retain) LPRGPUImageFrameBuffer *outputFramebuffer;
@property (nonatomic, assign) int pts;
@property (nonatomic, assign) BOOL data_ready;
@property (nonatomic, assign) BOOL not_check_new;

- (id)initWithAsset:(AVAsset *)asset;

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem;

- (void)yuvConversionSetup;

- (void)startProcessing;

- (void)endProcessing;

- (void)cancelProcessing;

- (BOOL)copyNextFrame;

- (void)processPtsFrameBufferWithTime:(CMTime)time;

- (void)processPixelBufferAtTimeWithTime:(CMTime)time;


@end

NS_ASSUME_NONNULL_END
