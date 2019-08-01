//
//  time_wheel.cpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/31.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include <stdio.h>
#include <iostream>
#include <functional>
#include "TimeWheel.h"
using namespace std;

void fun100()
{
    cout << "func 100" << endl;
}
void fun200()
{
    cout << "func 200" << endl;
}
void fun500()
{
    cout << "func 500" << endl;
}

void fun1500()
{
    cout << "func 1500" << endl;
}

void main()
{
    std::function<void(void)> f100 = std::bind(&fun100);
    std::function<void(void)> f200 = std::bind(&fun200);
    std::function<void(void)> f500 = std::bind(&fun500);
    std::function<void(void)> f1500 = std::bind(&fun1500);
    
    TimeWheel time_wheel;
    time_wheel.InitTimerWheel(100, 5);
    int timer1 = time_wheel.AddTimer(100, f100);
    int timer2 = time_wheel.AddTimer(200, f200);
    int timer3 = time_wheel.AddTimer(500, f500);
    //    time_wheel.AddTimer(1500, f1500);
    
    bool b = true;
    int nLoop = 0;
    while (1)
    {
        nLoop++;
        this_thread::sleep_for(chrono::milliseconds(300));
        if (b)
        {
            time_wheel.AddTimer(1500, f1500);
            b = false;
        }
        if (nLoop == 3)
            time_wheel.DeleteTimer(timer1);
    }
}
