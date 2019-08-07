//
//  GPUImageMovie.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/7.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageMovie : NSObject

@property (readwrite, retain) AVPlayerItem *playerItem;

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem;

- (void)yuvConversionSetup;

- (void)startProcessing;

- (void)endProcessing;

- (void)cancelProcessing;

- (BOOL)copyNextFrame;

@end

NS_ASSUME_NONNULL_END
