//
//  GCDCountDown.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/1.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCDCountDown : NSObject

@property (nonatomic, strong) dispatch_source_t timer;
+ (instancetype)manager;
- (void)resume;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
