//
//  GCDCountDown.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/1.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "GCDCountDown.h"

@implementation GCDCountDown

+ (instancetype)manager
{
    static GCDCountDown *countDown = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (countDown == nil) {
            countDown = [[GCDCountDown alloc]init];
        }
    });
    return countDown;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self loadTimer];
    }
    return self;
}

- (void)timerAction
{
    
}

//定时器设置
- (void)loadTimer
{
    if (self.timer)
    {
        dispatch_cancel(self.timer);
        self.timer = nil;
    }
    dispatch_queue_t queue = dispatch_get_main_queue();
    //创建一个定时器（dispatch_source_t本质上还是一个OC对象）
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    //设置定时器的各种属性
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0*NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(1.0*NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer, start, interval, 0);
    
    //设置回调
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.timer, ^{
        //定时器需要执行的操作
        [weakSelf timerAction];
    });
    //启动定时器（默认是暂停）
    dispatch_resume(self.timer);
}

- (void)resume
{
    //重新加载一次定时器
    [self loadTimer];
}

- (void)pause
{
    if (self.timer)
    {
        dispatch_cancel(self.timer);
        self.timer = nil;
    }
}

@end
