//
//  LPRGPUImageFrameBuffer.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRGPUImageFrameBuffer : NSObject

@property(readonly) GLuint texture;
@property(readonly) CGSize size;

- (id)initWithSize:(CGSize)framebufferSize;
- (void)activateFramebuffer;

@end

NS_ASSUME_NONNULL_END
