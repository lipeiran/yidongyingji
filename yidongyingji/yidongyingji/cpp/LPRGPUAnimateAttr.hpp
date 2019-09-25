//
//  GPUAnimateAttr.hpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/30.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef GPUAnimateAttr_hpp
#define GPUAnimateAttr_hpp

#include <stdio.h>
#import "Header.h"

class LPRGPUAnimateAttr {
public:
    float anchorPX = 0.5f;
    float anchorPY = 0.5f;
    float rotateAngle = 0.0f;
    float rotateAngleX = 0.0f;
    float rotateAngleY = 0.0f;
    float rotateAngleZ = 0.0f;
    float scaleX = 1.0f;
    float scaleY = 1.0f;
    float scaleZ = 1.0f;
    float deltaX = 0.0f;
    float deltaY = 0.0f;
    float deltaZ = 0.0f;
    float alpha = 1.0f;
private:
    
};

#endif /* GPUAnimateAttr_hpp */
