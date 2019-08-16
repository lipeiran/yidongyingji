//
//  LPRGPUImageContext.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRGPUImageFrameBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRGPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readonly, retain, nonatomic) EAGLContext *context;

+ (void *)contextKey;
+ (LPRGPUImageContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (void)useImageProcessingContext;
- (void)useAsCurrentContext;

- (void)presentBufferForDisplay;

@end

NS_ASSUME_NONNULL_END
