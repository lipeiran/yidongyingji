//
//  TimeWheel.cpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/31.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "TimeWheel.hpp"
#include <iostream>
using namespace std;

TimeWheel::TimeWheel()
{
    memset(&_time_pos, 0, sizeof(_time_pos));
    
}


TimeWheel::~TimeWheel()
{
}
int TimeWheel::InitTimerWheel(int step_ms, int max_min)
{
    if (1000 % step_ms != 0)
    {
        cout << "step is not property, should be devided by 1000" << endl;
        return -1;
    }
    int msNeedCount = 1000 / step_ms;
    int sNeedCount = 60;
    int minNeedCount = max_min;
    
    _pCallbackList = new std::list<EventInfo>[msNeedCount + sNeedCount + minNeedCount];
    _step_ms = step_ms;
    
    _lowCount = msNeedCount;
    _midCount = sNeedCount;
    _highCount = minNeedCount;
    
    std::thread th([&]{
        this->DoLoop();
    });
    
    th.detach();
    return 0;
}
int TimeWheel::AddTimer(int interval, std::function<void(void)>& call_back)
{
    if (interval < _step_ms || interval % _step_ms != 0 || interval >= _step_ms * _lowCount * _midCount * _highCount)
    {
        cout << "time interval is invalid" << endl;
        return -1;
    }
    
    std::unique_lock<std::mutex> lock(_mutex);
    
    EventInfo einfo = {0};
    einfo.interval = interval;
    einfo.call_back = call_back;
    einfo.time_pos.ms_pos = _time_pos.ms_pos;
    einfo.time_pos.s_pos = _time_pos.s_pos;
    einfo.time_pos.min_pos = _time_pos.min_pos;
    einfo.timer_id = GenerateTimerID();
    
    InsertTimer(einfo.interval,einfo);
    
    _timer_count++;
    
    cout << "insert timer success time_id: " << einfo.timer_id << endl;
    return einfo.timer_id;
}
int TimeWheel::DeleteTimer(int time_id)
{
    std::unique_lock<std::mutex> lock(_mutex);
    int i = 0;
    int nCount = _lowCount + _midCount + _highCount;
    for (i = 0; i < nCount; i++)
    {
        std::list<EventInfo>& leinfo = _pCallbackList[i];
        for (auto item = leinfo.begin(); item != leinfo.end();item++)
        {
            if (item->timer_id == time_id)
            {
                item = leinfo.erase(item);
                return 0;
            }
        }
    }
    
    if (i == nCount)
    {
        cout << "timer not found" << endl;
        return -1;
    }
    
    return 0;
}
int TimeWheel::DoLoop()
{
    cout << "........starting loop........" << endl;
    static int nCount = 0;
    while (true)
    {
        this_thread::sleep_for(chrono::milliseconds(_step_ms));
        std::unique_lock<std::mutex> lock(_mutex);
        cout << ".........this is " << ++nCount <<"  loop........."<< endl;
        TimePos pos = {0};
        TimePos last_pos = _time_pos;
        GetNextTrigerPos(_step_ms, pos);
        _time_pos = pos;
        
        if (pos.min_pos != last_pos.min_pos)
        {
            list<EventInfo>& leinfo = _pCallbackList[_time_pos.min_pos + _midCount + _lowCount];
            DealTimeWheeling(leinfo);
            leinfo.clear();
        }
        else if (pos.s_pos != last_pos.s_pos)
        {
            list<EventInfo>& leinfo = _pCallbackList[_time_pos.s_pos + _lowCount];
            DealTimeWheeling(leinfo);
            leinfo.clear();
        }
        else if (pos.ms_pos != last_pos.ms_pos)
        {
            list<EventInfo>& leinfo = _pCallbackList[_time_pos.ms_pos];
            DealTimeWheeling(leinfo);
            leinfo.clear();
        }
        else
        {
            cout << "error time not change" << endl;
            return -1;
        }
        lock.unlock();
    }
    return 0;
}
int TimeWheel::GenerateTimerID()
{
    int x = rand() % 0xffffffff;
    int cur_time = time(nullptr);
    return x | cur_time | _timer_count;
}

int TimeWheel::InsertTimer(int diff_ms,EventInfo &einfo)
{
    TimePos time_pos = {0};
    
    GetNextTrigerPos(diff_ms, time_pos);
    
    if (time_pos.min_pos != _time_pos.min_pos)
        _pCallbackList[_lowCount + _midCount + time_pos.min_pos].push_back(einfo);
    else if (time_pos.s_pos != _time_pos.s_pos)
        _pCallbackList[_lowCount + time_pos.s_pos].push_back(einfo);
    else if (time_pos.ms_pos != _time_pos.ms_pos)
        _pCallbackList[time_pos.ms_pos].push_back(einfo);
    
    return 0;
}

int TimeWheel::GetNextTrigerPos(int interval, TimePos& time_pos)
{
    int cur_ms = GetMS(_time_pos);
    int future_ms = cur_ms + interval;
    
    time_pos.min_pos = (future_ms / 1000 / 60) % _highCount;
    time_pos.s_pos = (future_ms % (1000 * 60)) / 1000;
    time_pos.ms_pos = (future_ms % 1000) / _step_ms;
    
    return 0;
}

int TimeWheel::GetMS(TimePos time_pos)
{
    return _step_ms * time_pos.ms_pos + time_pos.s_pos * 1000 + time_pos.min_pos * 60 * 1000;
}

int TimeWheel::DealTimeWheeling(std::list<EventInfo> leinfo)
{
    for (auto item = leinfo.begin(); item != leinfo.end(); item++)
    {
        int cur_ms = GetMS(_time_pos);
        int last_ms = GetMS(item->time_pos);
        int diff_ms = (cur_ms - last_ms + (_highCount + 1) * 60 * 1000) % ((_highCount + 1) * 60 * 1000);
        if (diff_ms == item->interval)
        {
            item->call_back();
            
            item->time_pos = _time_pos;
            InsertTimer(item->interval, *item);
        }
        else
        {
            InsertTimer(item->interval - diff_ms, *item);
        }
    }
    return 0;
}
