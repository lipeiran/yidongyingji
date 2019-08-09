//
//  AVPlayer+SeekSmoothly.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/9.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVPlayer (SeekSmoothly)

- (void)ss_seekToTime:(CMTime)time;

- (void)ss_seekToTime:(CMTime)time
      toleranceBefore:(CMTime)toleranceBefore
       toleranceAfter:(CMTime)toleranceAfter
    completionHandler:(void (^)(BOOL))completionHandler;

@end
