//
//  AE_struct.h
//  FFTest
//
//  Created by 李沛然 on 2019/6/5.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef AE_struct_h
#define AE_struct_h

#include <stdbool.h>
#include <float.h>

typedef struct{
    float x;
    float y;
}AEPoint;

typedef struct{
    AEPoint i;
    AEPoint o;
    char *n;
    int t;          // 第几帧
    float *s;       // 开始
    int s_num;
    float *e;       // 结束
    int e_num;
    float *to;
    int to_num;
    float *ti;
    int ti_num;
}AELayerKsKEntity;

typedef struct{
    int a;
    int ix;
    AELayerKsKEntity *k_entity; // 有动画的时候，AELayerKsKEntity数组
    int k_entity_num;
    float *k_float;             // 当属于 p，a，s的时候，float数组
    int k_float_num;
    float k;                    // 当属于 o，r的时候，为一个float值
}AEDicValueEntity;

typedef struct{
    AEDicValueEntity o;        // opacity不透明度，keys：a,k,ix
    AEDicValueEntity r;        // rotation旋转度，keys：a,k,ix
    AEDicValueEntity rx;        // rotation旋转度，keys：a,k,ix
    AEDicValueEntity ry;        // rotation旋转度，keys：a,k,ix
    AEDicValueEntity rz;        // rotation旋转度，keys：a,k,ix
    AEDicValueEntity p;        // position位置，keys：a,k,ix
    AEDicValueEntity a;        // anchor锚点，keys：a,k,ix
    AEDicValueEntity s;        // scale缩放，keys：a,k,ix
}AELayerKsEntity;

typedef struct{
    char *ty;
    int d;
    AEDicValueEntity *s;        // keys: a,k,ix
    AEDicValueEntity *p;        // keys: a,k,ix
    AEDicValueEntity *r;        // keys: a,k,ix
    char *nm;
    char *mn;
    bool hd;
}AELayerShapeItEntity;

typedef struct{
    char *ty;
    AELayerShapeItEntity *it;
    char *nm;
    int np;
    int cix;
    int ix;
    char *mn;
    bool hd;
}AELayerShapeEntity;

typedef struct AELayerEffectEntity_struct{
    int ty;
    char *nm;
    int np;
    char *mn;
    int ix;
    int en;
    struct AELayerEffectEntity_struct *ef;
    AEDicValueEntity v;
    int ip;
    int op;
    int st;
    int bm;
}AELayerEffectEntity;

typedef struct{
    char *nm;       // layer的名称，在ae中生成唯一
    int ind;        // layer的id，唯一
    int ty;         // layer的类型，为数字
    char *refId;    // 引用的资源，图片/预合成层
    int parent;     // 父图层的id，默认都添加到根图层上，如果指定了id不为0，会寻找父图层并添加到上面
    int ip;         // 该图层的起始关键帧
    int op;         // 该图层的结束关键帧
    float w;        // 预合成层：宽度
    float h;        // 预合成层：高度
    float sw;       // 固态层：宽度
    float sh;       // 固态层：高度
    char *sc;       // 固态层：颜色
    AELayerKsEntity ks;    // 外观信息
    AELayerEffectEntity *ef;
    char *tt;       // 遮罩类型
    char **masksProperties; // 蒙版数组
    AELayerShapeEntity *shapes; // 矢量图形图层的数组
    bool hasMask; // 是否有mask
    int z_index;
    // extension------------------------------start//
    int ddd;
    char *cl;
    int sr;
    int ao;
    int st;
    int bm;
    int layer_w = 0;
    int layer_h = 0;
    int asset_index = -1;
    // extension------------------------------end//
}AELayerEntity;

typedef struct AEAssetEntity{
    char *id;   // 图片唯一识别id，涂层获取图片的标识
    float w;    // 图片的宽度
    float h;    // 图片的高度
    char *u;    // 图片的路径，实际并未使用，例：images/
    char *p;    // 图片的名称，例：img_0.png
    AELayerEntity *layers;
}AEAssetEntity;

typedef struct{
    char *v;    // 使用的版本
    char *nm;   // 名字
    float w;    // 视图宽度
    float h;    // 视图高度
    int ip;     // 起始关键帧
    int op;     // 结束关键帧
    int fr;     // 帧率
    int ddd;
    AEAssetEntity *assets;      // 包含所有资源
    int assets_num;             // 资源数量
    AELayerEntity *layers;      // 包含所有涂层
    int layers_num;             // 涂层数量
}AEConfigEntity;

#endif /* AE_struct_h */
