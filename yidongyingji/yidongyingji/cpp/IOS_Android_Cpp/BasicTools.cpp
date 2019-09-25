//
//  Tools.cpp
//  FFTest
//
//  Created by 李沛然 on 2019/7/19.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "BasicTools.h"

// 某个字符串是否包含某个字符串
int str_isIn_str(char *s,const char *c)
{
    int i=0,j=0,flag=-1;
    while(i<strlen(s) && j<strlen(c))
    {
        if(s[i]==c[j])
        {
            //如果字符相同则两个字符都增加
            i++;
            j++;
        }
        else
        {
            i=i-j+1; //主串字符回到比较最开始比较的后一个字符
            j=0;     //字串字符重新开始
        }
        if(j==strlen(c))
        {
            //如果匹配成功
            flag=1;  //字串出现
            break;
        }
    }
    return flag;
}

// 获取整型长度
int length_int(int num)
{
    int length = 0;
    while(num)//当n不等于0时执行循环
    {
        num = num/10;//n的长度减去1
        length++;//length+1
    }
    return length;
}

// 替换字符串
char *replace_subStr(const char* str, const char* srcSubStr, const char* dstSubStr, char* out)
{
    char *p;
    char *_out = out;
    const char *_str = str;
    const char *_src = srcSubStr;
    const char *_dst = dstSubStr;
    long src_size = strlen(_src);
    long dst_size = strlen(_dst);
    long len = 0;
    do
    {
        p = (char *)strstr(_str, _src);
        if(p == 0)
        {
            strcpy(_out, _str);
            return out;
        }
        len = p - _str;
        memcpy(_out, _str, len);
        memcpy(_out + len, _dst, dst_size);
        _str = p + src_size;
        _out = _out + len + dst_size;
        
    } while(p);
    return out;
}

// 分割字符串为数组
char **split(const char *source, char flag ,int *split_count)
{
    char **pt;
    long j, n = 0;
    int count = 1;
    long len = strlen(source);
    char tmp[len + 1];
    tmp[0] = '\0';
    int i;
    for ( i = 0; i < len; ++i)
    {
        if (source[i] == flag && source[i+1] == '\0')
            continue;
        else if (source[i] == flag && source[i+1] != flag)
            count++;
    }
    // 多分配一个char*，是为了设置结束标志
    pt = (char**)malloc((count+1) * sizeof(char*));
    
    count = 0;
    for ( i = 0; i < len; ++i)
    {
        if (i == len - 1 && source[i] != flag)
        {
            tmp[n++] = source[i];
            tmp[n] = '\0';  // 字符串末尾添加空字符
            j = strlen(tmp) + 1;
            pt[count] = (char*)malloc(j * sizeof(char));
            strcpy(pt[count++], tmp);
        }
        else if (source[i] == flag)
        {
            j = strlen(tmp);
            if (j != 0)
            {
                tmp[n] = '\0';  // 字符串末尾添加空字符
                pt[count] = (char*)malloc((j+1) * sizeof(char));
                strcpy(pt[count++], tmp);
                // 重置tmp
                n = 0;
                tmp[0] = '\0';
            }
        }
        else
            tmp[n++] = source[i];
    }
    // 设置结束标志
    pt[count] = NULL;
    *split_count = count;
    return pt;
}

// 获取当前文件的上级路径
void get_pwd(const char *str, char *out)
{
    int tmp_i = 0;
    char **tmp_list = split(str, '/', &tmp_i);
    int i;
    for ( i = 0; i < tmp_i-1; i++)
    {
        strcat(out, "/");
        strcat(out, tmp_list[i]);
        if (i == (tmp_i-2))
        {
            strcat(out, "/");
        }
    }
}








