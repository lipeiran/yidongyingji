//
//  GPUImage.hpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/30.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef GPUImage_hpp
#define GPUImage_hpp

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include "utils.hpp"

class LPRGPUImage {
public:
    GLubyte *byte;
    int index;
    int w;
    int h;
    GLfloat vertexData_dst_lpr[30];
private:
    
};

#endif /* GPUImage_hpp */
