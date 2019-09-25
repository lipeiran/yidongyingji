//
//  Tools.hpp
//  FFTest
//
//  Created by 李沛然 on 2019/7/19.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef Tools_hpp
#define Tools_hpp

#include <stdio.h>
#include <string>
extern "C"{
#include <string.h>
}

// 查询子字符串是否在源字符串中
int str_isIn_str(char *s,const char *c);

// 获取数字长度
int length_int(int num);

// 替换字符串
char *replace_subStr(const char* str, const char* srcSubStr, const char* dstSubStr, char* out);

// 分割字符串为数组
char **split(const char *source, char flag ,int *split_count);

// 获取当前文件的上级路径
void get_pwd(const char *str, char *out);

#endif /* Tools_hpp */
