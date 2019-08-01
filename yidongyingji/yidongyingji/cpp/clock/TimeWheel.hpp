//
//  TimeWheel.hpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/31.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef TimeWheel_hpp
#define TimeWheel_hpp
/************************************************************************/
/* TimeWheel实现了一个毫秒级别的定时器，最大支持到分钟级别                                                                     */
/************************************************************************/

#pragma once
#include <functional>
#include <list>
#include <thread>
#include <mutex>

typedef struct TimePos_
{
    int ms_pos;
    int s_pos;
    int min_pos;
}TimePos;

typedef struct EventInfo_
{
    int interval;
    std::function<void(void)> call_back;
    TimePos time_pos;
    int timer_id;
    
}EventInfo;

class GPUImageFilter;

class TimeWheel
{
public:
    TimeWheel();
    ~TimeWheel();
public:
    /*step 以毫秒为单位，表示定时器最小时间粒度
     *max_timer 表示定时器所能接受的分钟时间间隔
     */
    int InitTimerWheel(int step,int max_min);
    int AddTimer(int interval, std::function<void(void)>& call_back);
    int DeleteTimer(int timer_id);
    
private:
    int DoLoop();
    int GenerateTimerID();
    int InsertTimer(int diff_ms,EventInfo& einfo);
    int GetNextTrigerPos(int interval,TimePos& time_pos);
    int GetMS(TimePos time_pos);
    int DealTimeWheeling(std::list<EventInfo> leinfo);
private:
    std::list<EventInfo> *_pCallbackList = nullptr;
    std::mutex _mutex;
    
    TimePos _time_pos;
    
    int _lowCount = 0;
    int _midCount = 0;
    int _highCount = 0;
    
    int _step_ms = 0;
    
    int _timer_count = 0;
    
};


#endif /* TimeWheel_hpp */
