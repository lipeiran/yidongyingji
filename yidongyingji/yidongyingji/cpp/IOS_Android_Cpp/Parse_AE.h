//
//  Parse_AE.h
//  FFTest
//
//  Created by 李沛然 on 2019/7/19.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef Parse_AE_h
#define Parse_AE_h

#include <stdio.h>
#include "AE_struct.h"
#include <string>
#include "BasicTools.hpp"
#include "cJSON.h"


class ParseAE{
public:
    // 获取 asset 的序号
    static int asset_index_refId(char *refId, AEConfigEntity &configEntity);
    // 获取 layer 的序号
    static int layer_index_ind(int ind, AEConfigEntity &configEntity);
    // 解析 ae json 配置文件
    static void dofile(char *filename,AEConfigEntity &tmpEntity);
    // 获取相应浮层的属性值，r，o，a，s，p
    static void get_ae_params(int i, AELayerEntity tmpLayerEntity, float *angle_f_v, float *scale_f_x_v, float *scale_f_y_v, float *x_f_v, float *y_f_v, float *anchor_x_f_v, float *anchor_y_f_v, float *alpha_f_v, int *blur_radius_v);
    static void get_ae_params_3D(int i, AELayerEntity tmpLayerEntity, float *angle_f_v, float *angle_fx_v, float *angle_fy_v, float *angle_fz_v, float *scale_f_x_v, float *scale_f_y_v, float *x_f_v, float *y_f_v, float *anchor_x_f_v, float *anchor_y_f_v, float *alpha_f_v, int *blur_radius_v);
    static void parse_mask_layer(char *mask_img_path_str, char *mask_img_ind_str, char *mask_img_ref_id_str, int &mask_count, int total_layernum, AELayerEntity *layers, char *src_config_file_path);
private:
    static void doit(char *text, AEConfigEntity &configEntity);
};



#endif /* Parse_AE_h */
