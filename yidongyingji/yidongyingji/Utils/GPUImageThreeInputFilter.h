//
//  GPUImageThreeInputFilter.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/7.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImageFrameBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageThreeInputFilter : NSObject
{
    GPUImageFrameBuffer *firstInputFramebuffer;
    GPUImageFrameBuffer *secondInputFramebuffer;
    GPUImageFrameBuffer *thirdInputFramebuffer;
    
    GPUImageFrameBuffer *outputFrameBuffer;
}

- (void)startDraw;

- (void)endDraw;

@end

NS_ASSUME_NONNULL_END
