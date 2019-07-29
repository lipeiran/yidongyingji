//
//  Parse_AE.cpp
//  FFTest
//
//  Created by 李沛然 on 2019/7/19.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "Parse_AE.h"
#include <iostream>
#include "math.h"

/* Parse text to JSON, then render back to text, and print! */
void ParseAE::doit(char *text, AEConfigEntity &configEntity)
{
    char *out;
    cJSON *json;
    cJSON *tmpJson;
    json=cJSON_Parse(text);
    if (!json)
    {
        printf("Error before: [%s]\n",cJSON_GetErrorPtr());
    }
    else
    {
        // AEConfigEntity: v,nm,w,h,ip,op,fr 解析
        tmpJson = cJSON_GetObjectItem(json, "v");
        char *v_string = tmpJson?tmpJson->valuestring:NULL;
        tmpJson = cJSON_GetObjectItem(json, "nm");
        char *nm_string = tmpJson?tmpJson->valuestring:NULL;
        tmpJson = cJSON_GetObjectItem(json, "w");
        float w_float = tmpJson?tmpJson->valuedouble:0;
        tmpJson = cJSON_GetObjectItem(json, "h");
        float h_float = tmpJson?tmpJson->valuedouble:0;
        tmpJson = cJSON_GetObjectItem(json, "ip");
        int ip_int = tmpJson?tmpJson->valueint:0;
        tmpJson = cJSON_GetObjectItem(json, "op");
        int op_int = tmpJson?tmpJson->valueint:0;
        tmpJson = cJSON_GetObjectItem(json, "fr");
        int fr_int = tmpJson?tmpJson->valueint:0;
        
        // AEConfigEntity: assets 解析
        cJSON *assetArrayItem = NULL;
        assetArrayItem = cJSON_GetObjectItem(json, "assets");
        int assetArraySize = cJSON_GetArraySize(assetArrayItem);
        AEAssetEntity *assetsEntity = NULL;
        assetsEntity = (AEAssetEntity *)malloc(assetArraySize * sizeof(*assetsEntity));
        int i = 0;
        for ( i = 0; i < assetArraySize; i++)
        {
            cJSON *assetsObject = cJSON_GetArrayItem(assetArrayItem, i);
            tmpJson = cJSON_GetObjectItem(assetsObject, "id");
            char *id_string = tmpJson?tmpJson->valuestring:NULL;
            tmpJson = cJSON_GetObjectItem(assetsObject, "w");
            float w_float = tmpJson?tmpJson->valuedouble:0;
            tmpJson = cJSON_GetObjectItem(assetsObject, "h");
            float h_float = tmpJson?tmpJson->valuedouble:0;
            tmpJson = cJSON_GetObjectItem(assetsObject, "u");
            char *u_string = tmpJson?tmpJson->valuestring:NULL;
            tmpJson = cJSON_GetObjectItem(assetsObject, "p");
            char *p_string = tmpJson?tmpJson->valuestring:NULL;
            
            assetsEntity[i].id = id_string;
            assetsEntity[i].w = w_float;
            assetsEntity[i].h = h_float;
            assetsEntity[i].u = u_string;
            assetsEntity[i].p = p_string;
            
            // AELayerEntity *layers，暂时不考虑
        }
        // AEConfigEntity: layers 解析
        cJSON *layersArrayItem = NULL;
        layersArrayItem = cJSON_GetObjectItem(json, "layers");
        int layerArraySize = cJSON_GetArraySize(layersArrayItem);
        AELayerEntity *layersEntity = NULL;
        layersEntity = (AELayerEntity *)malloc(layerArraySize * sizeof(*layersEntity));

        const int ks_char_count = 5;
        const char *ks_char[5] = {"o","r","p","a","s"};
        for ( i = 0; i < layerArraySize; i++)
        {
            cJSON *layersObject = cJSON_GetArrayItem(layersArrayItem, i);
            tmpJson = cJSON_GetObjectItem(layersObject, "nm");
            char *nm_string = tmpJson?tmpJson->valuestring:NULL;
            tmpJson = cJSON_GetObjectItem(layersObject, "ind");
            int ind_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "ty");
            int ty_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "refId");
            char *refId_string = tmpJson?tmpJson->valuestring:NULL;
            tmpJson = cJSON_GetObjectItem(layersObject, "parent");
            int parent_int = tmpJson?tmpJson->valueint:-1;
            tmpJson = cJSON_GetObjectItem(layersObject, "ip");
            int ip_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "op");
            int op_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "w");
            float w_float = tmpJson?tmpJson->valuedouble:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "h");
            float h_float = tmpJson?tmpJson->valuedouble:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "sw");
            float sw_float = tmpJson?tmpJson->valuedouble:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "sh");
            float sh_float = tmpJson?tmpJson->valuedouble:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "sc");
            char *sc_string = tmpJson?tmpJson->valuestring:NULL;
            tmpJson = cJSON_GetObjectItem(layersObject, "tt");
            char *tt_string = tmpJson?tmpJson->valuestring:NULL;
            tmpJson = cJSON_GetObjectItem(layersObject, "hasMask");
            bool mask_int = tmpJson?tmpJson->valueint:false;
            // extension------------------------------start//
            tmpJson = cJSON_GetObjectItem(layersObject, "ddd");
            int ddd_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "cl");
            char *cl_string = tmpJson?tmpJson->valuestring:NULL;
            tmpJson = cJSON_GetObjectItem(layersObject, "sr");
            int sr_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "ao");
            int ao_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "st");
            int st_int = tmpJson?tmpJson->valueint:0;
            tmpJson = cJSON_GetObjectItem(layersObject, "bm");
            int bm_int = tmpJson?tmpJson->valueint:0;
            // extension------------------------------end//
            
            layersEntity[i].nm = nm_string;
            layersEntity[i].ind = ind_int;
            layersEntity[i].ty = ty_int;
            layersEntity[i].refId = refId_string;
            layersEntity[i].hasMask = mask_int;
            layersEntity[i].parent = parent_int;
            layersEntity[i].ip = ip_int;
            layersEntity[i].op = op_int;
            layersEntity[i].w = w_float;
            layersEntity[i].h = h_float;
            layersEntity[i].sw = sw_float;
            layersEntity[i].sh = sh_float;
            layersEntity[i].sc = sc_string;
            layersEntity[i].tt = tt_string;
            layersEntity[i].masksProperties = NULL;
            layersEntity[i].z_index = i;
            // extension------------------------------start//
            layersEntity[i].ddd = ddd_int;
            layersEntity[i].cl = cl_string;
            layersEntity[i].sr = sr_int;
            layersEntity[i].ao = ao_int;
            layersEntity[i].st = st_int;
            layersEntity[i].bm = bm_int;
            // extension------------------------------end//
            
            // AELayerShapeEntity *shapes，暂时不考虑
            // AELayerKsEntity *ks
            cJSON *ksDicJson = NULL;
            cJSON *ksSubDicJson = NULL;
            int a_int = 0;
            int ix_int = 0;
            float k_float = 0;
            int layerKAttrArraySize = 0;
            AEDicValueEntity tmpDicValueSets[ks_char_count];
            int tmp_i = 0;
            for ( tmp_i = 0; tmp_i < ks_char_count; tmp_i++)
            {
                tmpDicValueSets[tmp_i].a = 0;
                tmpDicValueSets[tmp_i].ix = 0;
                tmpDicValueSets[tmp_i].k_entity = NULL;
                tmpDicValueSets[tmp_i].k_entity_num = 0;
                tmpDicValueSets[tmp_i].k_float = NULL;
                tmpDicValueSets[tmp_i].k_float_num = 0;
                tmpDicValueSets[tmp_i].k = 0;
            }
            tmpJson = cJSON_GetObjectItem(layersObject, "ks");
            AELayerKsEntity layerKsEntity;
            int index;
            for ( index = 0; index < ks_char_count; index++)
            {
                ksDicJson = cJSON_GetObjectItem(tmpJson, ks_char[index]);
                if (index == 1) // 获取 r 的值
                {
                    if (ksDicJson == NULL)
                    {
                        ksDicJson = cJSON_GetObjectItem(tmpJson, "rz");
                    }
                }
                
                ksSubDicJson = ksDicJson?cJSON_GetObjectItem(ksDicJson, "a"):NULL;
                a_int = ksSubDicJson?ksSubDicJson->valueint:0;
                ksSubDicJson = ksDicJson?cJSON_GetObjectItem(ksDicJson, "ix"):NULL;
                ix_int = ksSubDicJson?ksSubDicJson->valueint:0;
                tmpDicValueSets[index].a = a_int;   // 赋值a
                tmpDicValueSets[index].ix = ix_int; // 赋值ix
                ksSubDicJson = ksDicJson?cJSON_GetObjectItem(ksDicJson, "k"):NULL;
                layerKAttrArraySize = ksSubDicJson?cJSON_GetArraySize(ksSubDicJson):0;
                if (layerKAttrArraySize == 0)
                {
                    k_float = ksSubDicJson?ksSubDicJson->valuedouble:0;
                    tmpDicValueSets[index].k = k_float;
                    tmpDicValueSets[index].k_float = NULL;
                    tmpDicValueSets[index].k_entity = NULL;
                    tmpDicValueSets[index].k_float_num = 0;
                    tmpDicValueSets[index].k_entity_num = 0;
                }
                else
                {
                    cJSON *k_entity_json = cJSON_GetArrayItem(ksSubDicJson, 0);
                    cJSON *k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "t"):NULL;    // 检测是否存在 t 属性
                    bool animate_bool = k_attr_json?true:false;
                    if (animate_bool)
                    {
                        tmpDicValueSets[index].k_entity = (AELayerKsKEntity *)malloc(sizeof(AELayerKsKEntity)*layerKAttrArraySize);
                        tmpDicValueSets[index].k_entity_num = layerKAttrArraySize;
                    }
                    else
                    {
                        tmpDicValueSets[index].k_float = (float *)malloc(sizeof(float)*layerKAttrArraySize);
                        tmpDicValueSets[index].k_float_num = layerKAttrArraySize;
                        
                    }
                    int layerKSubAttrArraySize = 0;
                    cJSON *k_sub_attr_json;
                    int i;
                    for ( i = 0; i < layerKAttrArraySize; i++)
                    {
                        if (animate_bool) // 有动画
                        {
                            AELayerKsKEntity layerKsKEntity;
                            tmpDicValueSets[index].k_float = NULL;
                            tmpDicValueSets[index].k = 0;
                            k_entity_json = cJSON_GetArrayItem(ksSubDicJson, i);
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "i"):NULL;
                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "x"):NULL;
                            layerKsKEntity.i.x = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "y"):NULL;
                            layerKsKEntity.i.y = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "o"):NULL;
                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "x"):NULL;
                            layerKsKEntity.o.x = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "y"):NULL;
                            layerKsKEntity.o.y = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "n"):NULL;
                            char *n_string = k_attr_json?k_attr_json->valuestring:NULL;
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "t"):NULL;
                            int t_int = k_attr_json?k_attr_json->valueint:0;
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "s"):NULL;
                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                            layerKsKEntity.s = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                            layerKsKEntity.s_num = layerKSubAttrArraySize;
                            int m;
                            for ( m = 0; m < layerKSubAttrArraySize; m++)
                            {
                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m):NULL;
                                layerKsKEntity.s[m] = k_sub_attr_json->valuedouble;
                            }
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "e"):NULL;
                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                            layerKsKEntity.e = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                            layerKsKEntity.e_num = layerKSubAttrArraySize;
                            for ( m = 0; m < layerKSubAttrArraySize; m++)
                            {
                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m):NULL;
                                layerKsKEntity.e[m] = k_sub_attr_json->valuedouble;
                            }
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "to"):NULL;
                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                            layerKsKEntity.to = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                            layerKsKEntity.to_num = layerKSubAttrArraySize;
                            for ( m = 0; m < layerKSubAttrArraySize; m++)
                            {
                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m):NULL;
                                layerKsKEntity.to[m] = k_sub_attr_json->valuedouble;
                            }
                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "ti"):NULL;
                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                            layerKsKEntity.ti = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                            layerKsKEntity.ti_num = layerKSubAttrArraySize;
                            for ( m = 0; m < layerKSubAttrArraySize; m++)
                            {
                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m):NULL;
                                layerKsKEntity.ti[m] = k_sub_attr_json->valuedouble;
                            }
                            layerKsKEntity.n = n_string;
                            layerKsKEntity.t = t_int;
                            tmpDicValueSets[index].k_entity[i] = layerKsKEntity;
                        }
                        else    // 无动画
                        {
                            cJSON *k_sub_value_json = k_entity_json?cJSON_GetArrayItem(ksSubDicJson, i):NULL;
                            tmpDicValueSets[index].k_float[i] = k_sub_value_json->valuedouble;
                            tmpDicValueSets[index].k = 0;
                            tmpDicValueSets[index].k_entity = NULL;
                        }
                    }
                }
            }
            layerKsEntity.o = tmpDicValueSets[0];
            layerKsEntity.r = tmpDicValueSets[1];
            layerKsEntity.p = tmpDicValueSets[2];
            layerKsEntity.a = tmpDicValueSets[3];
            layerKsEntity.s = tmpDicValueSets[4];
            layersEntity[i].ks = layerKsEntity;
            // ks------------------------------end//
            
            cJSON *tmp_ef_Json = cJSON_GetObjectItem(layersObject, "ef");
            if (tmp_ef_Json)
            {
                int efSize = cJSON_GetArraySize(tmp_ef_Json);
                
                AELayerEffectEntity *efsEntity = NULL;
                efsEntity = (AELayerEffectEntity *)malloc(efSize * sizeof(*efsEntity));

                int m = 0;
                for ( m = 0; m < efSize; m++)
                {
                    cJSON *efObject = cJSON_GetArrayItem(tmp_ef_Json, m);
                    tmpJson = cJSON_GetObjectItem(efObject, "ty");
                    int ty_int = tmpJson?tmpJson->valueint:0;
                    tmpJson = cJSON_GetObjectItem(efObject, "nm");
                    char *nm_string = tmpJson?tmpJson->valuestring:NULL;
                    tmpJson = cJSON_GetObjectItem(efObject, "np");
                    int np_int = tmpJson?tmpJson->valueint:0;
                    tmpJson = cJSON_GetObjectItem(efObject, "mn");
                    char *mn_string = tmpJson?tmpJson->valuestring:NULL;
                    tmpJson = cJSON_GetObjectItem(efObject, "ix");
                    int ix_int = tmpJson?tmpJson->valueint:0;
                    tmpJson = cJSON_GetObjectItem(efObject, "en");
                    int en_int = tmpJson?tmpJson->valueint:0;
                    tmpJson = cJSON_GetObjectItem(efObject, "ef");
                    AELayerEffectEntity *sub_efsEntity = NULL;
                    if (tmpJson)
                    {
                        int sub_efSize = cJSON_GetArraySize(tmpJson);
                        sub_efsEntity = (AELayerEffectEntity *)malloc(sub_efSize * sizeof(*sub_efsEntity));

                        cJSON *tmp_Json = NULL;
                        int n = 0;
                        for ( n = 0; n < sub_efSize; n++)
                        {
                            cJSON *sub_efObject = cJSON_GetArrayItem(tmpJson, n);
                            tmp_Json = cJSON_GetObjectItem(sub_efObject, "ty");
                            int ty_int = tmp_Json?tmp_Json->valueint:0;
                            tmp_Json = cJSON_GetObjectItem(sub_efObject, "nm");
                            char *nm_string = tmp_Json?tmp_Json->valuestring:NULL;
                            tmp_Json = cJSON_GetObjectItem(sub_efObject, "mn");
                            char *mn_string = tmp_Json?tmp_Json->valuestring:NULL;
                            tmp_Json = cJSON_GetObjectItem(sub_efObject, "ix");
                            int ix_int = tmp_Json?tmp_Json->valueint:0;
                            tmp_Json = cJSON_GetObjectItem(sub_efObject, "v");
                            
                            AEDicValueEntity sub_v_entity;
                            sub_v_entity.a = 0;
                            sub_v_entity.ix = 0;
                            sub_v_entity.k_entity = NULL;
                            sub_v_entity.k_entity_num = 0;
                            sub_v_entity.k_float = NULL;
                            sub_v_entity.k_float_num = 0;
                            sub_v_entity.k = 0;
                            if (tmp_Json)
                            {
                                cJSON *tmp_sub_Json = NULL;
                                int k_value = 0;
                                tmp_sub_Json = cJSON_GetObjectItem(tmp_Json, "a");
                                int a_int = tmp_Json?tmp_Json->valueint:0;
                                tmp_sub_Json = cJSON_GetObjectItem(tmp_Json, "ix");
                                int ix_int = tmp_Json?tmp_Json->valueint:0;
                                tmp_sub_Json = cJSON_GetObjectItem(tmp_Json, "k");
                                
                                int k_int = tmp_sub_Json?cJSON_GetArraySize(tmp_sub_Json):0;
                                if (k_int == 0)
                                {
                                    k_value = tmp_sub_Json?tmp_sub_Json->valueint:0;
                                    sub_v_entity.k = k_value;
                                    sub_v_entity.k_float = NULL;
                                    sub_v_entity.k_entity = NULL;
                                }
                                else
                                {
                                    cJSON *k_entity_json = cJSON_GetArrayItem(tmp_sub_Json, 1);
                                    cJSON *k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "t"):NULL;    // 检测是否存在 t 属性
                                    bool animate_bool = k_attr_json?true:false;
                                    if (animate_bool)
                                    {
                                        sub_v_entity.k_entity = (AELayerKsKEntity *)malloc(sizeof(AELayerKsKEntity)*k_int);
                                        sub_v_entity.k_entity_num = k_int;
                                    }
                                    else
                                    {
                                        sub_v_entity.k_float = (float *)malloc(sizeof(float)*k_int);
                                        sub_v_entity.k_float_num = k_int;
                                    }
                                    int layerKSubAttrArraySize = 0;
                                    cJSON *k_sub_attr_json;
                                    int tmp_k_i = 0;
                                    for ( tmp_k_i = 0; tmp_k_i < k_int; tmp_k_i++)
                                    {
                                        if (animate_bool) // 有动画
                                        {
                                            AELayerKsKEntity layerKsKEntity;
                                            sub_v_entity.k_float = NULL;
                                            sub_v_entity.k = 0;
                                            k_entity_json = cJSON_GetArrayItem(tmp_sub_Json, tmp_k_i);
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "i"):NULL;
                                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "x"):NULL;
                                            layerKsKEntity.i.x = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "y"):NULL;
                                            layerKsKEntity.i.y = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "o"):NULL;
                                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "x"):NULL;
                                            layerKsKEntity.o.x = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                                            k_sub_attr_json = k_attr_json?cJSON_GetObjectItem(k_attr_json, "y"):NULL;
                                            layerKsKEntity.o.y = k_sub_attr_json?k_sub_attr_json->valuedouble:0;
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "n"):NULL;
                                            char *n_string = k_attr_json?k_attr_json->valuestring:NULL;
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "t"):NULL;
                                            int t_int = k_attr_json?k_attr_json->valueint:0;
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "s"):NULL;
                                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                                            layerKsKEntity.s = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                                            layerKsKEntity.s_num = layerKSubAttrArraySize;
                                            int m_i;
                                            for ( m_i = 0; m_i < layerKSubAttrArraySize; m_i++)
                                            {
                                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m_i):NULL;
                                                layerKsKEntity.s[m_i] = k_sub_attr_json->valuedouble;
                                            }
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "e"):NULL;
                                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                                            layerKsKEntity.e = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                                            layerKsKEntity.e_num = layerKSubAttrArraySize;
                                            for ( m_i = 0; m_i < layerKSubAttrArraySize; m_i++)
                                            {
                                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m_i):NULL;
                                                layerKsKEntity.e[m_i] = k_sub_attr_json->valuedouble;
                                            }
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "to"):NULL;
                                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                                            layerKsKEntity.to = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                                            layerKsKEntity.to_num = layerKSubAttrArraySize;
                                            for ( m_i = 0; m_i < layerKSubAttrArraySize; m_i++)
                                            {
                                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m_i):NULL;
                                                layerKsKEntity.to[m_i] = k_sub_attr_json->valuedouble;
                                            }
                                            k_attr_json = k_entity_json?cJSON_GetObjectItem(k_entity_json, "ti"):NULL;
                                            layerKSubAttrArraySize = k_attr_json?cJSON_GetArraySize(k_attr_json):0;
                                            layerKsKEntity.ti = (float *)malloc(sizeof(float)*layerKSubAttrArraySize);
                                            layerKsKEntity.ti_num = layerKSubAttrArraySize;
                                            for ( m_i = 0; m_i < layerKSubAttrArraySize; m_i++)
                                            {
                                                k_sub_attr_json = k_attr_json?cJSON_GetArrayItem(k_attr_json, m_i):NULL;
                                                layerKsKEntity.ti[m_i] = k_sub_attr_json->valuedouble;
                                            }
                                            layerKsKEntity.n = n_string;
                                            layerKsKEntity.t = t_int;
                                            sub_v_entity.k_entity[tmp_k_i] = layerKsKEntity;
                                        }
                                        else
                                        {
                                            cJSON *k_sub_value_json = k_entity_json?cJSON_GetArrayItem(tmp_sub_Json, i):NULL;
                                            sub_v_entity.k_float[i] = k_sub_value_json?k_sub_value_json->valuedouble:0;
                                            sub_v_entity.k = 0;
                                            sub_v_entity.k_entity = NULL;
                                        }
                                    }
                                }
                                
                                sub_v_entity.a = a_int;
                                sub_v_entity.ix = ix_int;
                            }
                            sub_efsEntity[n].ty = ty_int;
                            sub_efsEntity[n].nm = nm_string;
                            sub_efsEntity[n].mn = mn_string;
                            sub_efsEntity[n].ix = ix_int;
                            sub_efsEntity[n].v = sub_v_entity;
                        }
                    }
                    tmpJson = cJSON_GetObjectItem(efObject, "ip");
                    int ip_int = tmpJson?tmpJson->valueint:0;
                    tmpJson = cJSON_GetObjectItem(efObject, "op");
                    int op_int = tmpJson?tmpJson->valueint:0;
                    tmpJson = cJSON_GetObjectItem(efObject, "st");
                    int st_int = tmpJson?tmpJson->valueint:0;
                    tmpJson = cJSON_GetObjectItem(efObject, "bm");
                    int bm_int = tmpJson?tmpJson->valueint:0;
                    
                    efsEntity[m].ty = ty_int;
                    efsEntity[m].nm = nm_string;
                    efsEntity[m].np = np_int;
                    efsEntity[m].mn = mn_string;
                    efsEntity[m].ix = ix_int;
                    efsEntity[m].en = en_int;
                    efsEntity[m].ip = ip_int;
                    efsEntity[m].op = op_int;
                    efsEntity[m].st = st_int;
                    efsEntity[m].bm = bm_int;
                    efsEntity[m].ef = sub_efsEntity;
                    AEDicValueEntity v_entity;
                    v_entity.a = 0;
                    v_entity.ix = 0;
                    v_entity.k_entity = NULL;
                    v_entity.k_entity_num = 0;
                    v_entity.k_float = NULL;
                    v_entity.k_float_num = 0;
                    v_entity.k = 0;
                    efsEntity[m].v = v_entity;
                }
                layersEntity[i].ef = efsEntity;
            }
            else
            {
                layersEntity[i].ef = NULL;
            }
            // ef------------------------------end//
        }
        // AEConfigEntity: 解析结果最终赋值
        configEntity.v = v_string;
        configEntity.nm = nm_string;
        configEntity.w = w_float;
        configEntity.h = h_float;
        configEntity.ip = ip_int;
        configEntity.op = op_int;
        configEntity.fr = fr_int;
        configEntity.assets = assetsEntity;
        configEntity.layers = layersEntity;
        configEntity.assets_num = assetArraySize;
        configEntity.layers_num = layerArraySize;
        out=cJSON_Print(json);
    }
}

// 获取 asset 的序号
int ParseAE::asset_index_refId(char *refId,AEConfigEntity &configEntity)
{
    int i = 0;
    for ( i = 0; i < configEntity.assets_num; i++)
    {
        AEAssetEntity *tmpEntity = &configEntity.assets[i];
        if (strcmp(tmpEntity->id, refId) == 0)
        {
            return i;
        }
    }
    return -1;
}

// 获取 layer 的序号
int ParseAE::layer_index_ind(int ind,AEConfigEntity &configEntity)
{
    int i = -1;
    for ( i = 0; i < configEntity.layers_num; i++)
    {
        AELayerEntity *tmpEntity = &configEntity.layers[i];
        if (tmpEntity->ind == ind)
        {
            return i;
        }
    }
    return i;
}

// 解析 ae json 配置文件
void ParseAE::dofile(char *filename,AEConfigEntity &tmpEntity)
{
    FILE *f;
    long len;
    char *data;
    f=fopen(filename,"rb");
    fseek(f,0,SEEK_END);
    len=ftell(f);
    fseek(f,0,SEEK_SET);
    data=(char*)malloc(len+1);
    fread(data,1,len,f);
    fclose(f);
    doit(data,tmpEntity);
    free(data);
    data = NULL;
}

// 获取相应浮层的属性值，r，o，a，s，p
void ParseAE::get_ae_params(int i, AELayerEntity tmpLayerEntity, float *angle_f_v, float *scale_f_x_v, float *scale_f_y_v, float *x_f_v, float *y_f_v, float *anchor_x_f_v, float *anchor_y_f_v, float *alpha_f_v, int *blur_radius_v)
{
    float angle_f = 0;
    float scale_f_x = 1.0;
    float scale_f_y = 1.0;
    float x_f = 0;
    float y_f = 0;
    float anchor_x_f = 0;
    float anchor_y_f = 0;
    float alpha_f = 1.0;
    int blur_radius = 0.0;
    // 高斯模糊度
    const char *blur_str = "Blur";
    if (tmpLayerEntity.ef && tmpLayerEntity.ef[0].ef && str_isIn_str(tmpLayerEntity.ef[0].mn,blur_str) && tmpLayerEntity.ef[0].ef[0].v.k_entity_num > 0 )
    {
        int tmp_k_entity_num = tmpLayerEntity.ef[0].ef[0].v.k_entity_num;
        int ef_ip = tmpLayerEntity.ef[0].ef[0].v.k_entity[0].t;
        int ef_op = tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_entity_num-1].t;
        if (i >= ef_ip && i <= ef_op)
        {
            int tmp_k_index = 0;
            for (tmp_k_index = 0; tmp_k_index < tmp_k_entity_num; tmp_k_index++)
            {
                int tmp_k_t = tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_index].t;
                if (i == tmp_k_t)
                {
                    if (tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_index].s_num > 0)
                    {
                        blur_radius = (int)tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_index].s[0];
                    }
                    else
                    {
                        int tmp_sub_i = tmp_k_index;
                        while ((tmp_sub_i--) >=0)
                        {
                            if (tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_sub_i].s_num > 0)
                            {
                                blur_radius = (int)tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_sub_i].e[0];
                                break;
                            }
                        }
                    }
                    break;
                }
                else if (i < tmp_k_t)
                {
                    int tmp_pre_k_t = tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_index-1].t;
                    int tmp_pre_k_s_blur_radius = 0;
                    int tmp_pre_k_e_blur_radius = 0;
                    
                    if (tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_index-1].s_num > 0)
                    {
                        tmp_pre_k_s_blur_radius = tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_index-1].s[0];
                        tmp_pre_k_e_blur_radius = tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_k_index-1].e[0];
                    }
                    else
                    {
                        int tmp_sub_i = tmp_k_index-1;
                        while ((tmp_sub_i--) >=0)
                        {
                            if (tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_sub_i].s_num > 0)
                            {
                                tmp_pre_k_s_blur_radius = (int)tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_sub_i].s[0];
                                tmp_pre_k_e_blur_radius = (int)tmpLayerEntity.ef[0].ef[0].v.k_entity[tmp_sub_i].e[0];
                                break;
                            }
                        }
                    }
                    blur_radius = (int)(i-tmp_pre_k_t)*1.0/(tmp_k_t-tmp_pre_k_t)*(tmp_pre_k_e_blur_radius-tmp_pre_k_s_blur_radius)+tmp_pre_k_s_blur_radius;
                    break;
                }
            }
        }
        else
        {
            blur_radius = 0;
        }
    }
    else if (tmpLayerEntity.ef && tmpLayerEntity.ef[0].ef)
    {
        blur_radius = (int)tmpLayerEntity.ef[0].ef[0].v.k;
    }
    else
    {
        blur_radius = 0;
    }
    if (blur_radius < 0)
    {
        blur_radius = 0;
    }
    // 透明度
    if (tmpLayerEntity.ks.o.k_entity_num > 0)
    {
        if (i >= tmpLayerEntity.ip && i - tmpLayerEntity.ip < tmpLayerEntity.ks.o.k_entity_num)
        {
            if (tmpLayerEntity.ks.o.k_entity[i-tmpLayerEntity.ip].s_num > 0)
            {
                alpha_f = tmpLayerEntity.ks.o.k_entity[i-tmpLayerEntity.ip].s[0] / 100.0;
            }
            else
            {
                int tmp_i = 1;
                while (i - tmpLayerEntity.ip - tmp_i >=0)
                {
                    if (tmpLayerEntity.ks.o.k_entity[i-tmpLayerEntity.ip-tmp_i].s_num > 0)
                    {
                        alpha_f = tmpLayerEntity.ks.o.k_entity[i-tmpLayerEntity.ip-tmp_i].e[0] / 100.0;
                        break;
                    }
                    tmp_i++;
                }
            }
        }
        else
        {
            int tmp_i = 1;
            while (i - tmpLayerEntity.ip - tmp_i >=0)
            {
                if (tmpLayerEntity.ks.o.k_entity[i-tmpLayerEntity.ip-tmp_i].s_num > 0)
                {
                    alpha_f = tmpLayerEntity.ks.o.k_entity[i-tmpLayerEntity.ip-tmp_i].e[0] / 100.0;
                    break;
                }
                tmp_i++;
            }
        }
    }
    else
    {
        alpha_f = tmpLayerEntity.ks.o.k /100.0;
    }
    // 锚点
    if (tmpLayerEntity.ks.a.k_entity_num > 0)
    {
        if (i >= tmpLayerEntity.ip && i - tmpLayerEntity.ip < tmpLayerEntity.ks.a.k_entity_num)
        {
            if (tmpLayerEntity.ks.a.k_entity[i-tmpLayerEntity.ip].s_num > 0)
            {
                anchor_x_f = tmpLayerEntity.ks.a.k_entity[i-tmpLayerEntity.ip].s[0];
                anchor_y_f = tmpLayerEntity.ks.a.k_entity[i-tmpLayerEntity.ip].s[1];
            }
            else
            {
                int tmp_i = 1;
                while (i - tmpLayerEntity.ip - tmp_i >=0)
                {
                    if (tmpLayerEntity.ks.a.k_entity[i - tmpLayerEntity.ip - tmp_i].s_num > 0)
                    {
                        anchor_x_f = tmpLayerEntity.ks.a.k_entity[i - tmpLayerEntity.ip - tmp_i].e[0];
                        anchor_y_f = tmpLayerEntity.ks.a.k_entity[i - tmpLayerEntity.ip - tmp_i].e[1];
                        break;
                    }
                    tmp_i++;
                }
            }
        }
        else
        {
            int tmp_i = 1;
            while (i - tmpLayerEntity.ip - tmp_i >=0)
            {
                if (tmpLayerEntity.ks.a.k_entity[i - tmpLayerEntity.ip - tmp_i].s_num > 0)
                {
                    anchor_x_f = tmpLayerEntity.ks.a.k_entity[i - tmpLayerEntity.ip - tmp_i].e[0];
                    anchor_y_f = tmpLayerEntity.ks.a.k_entity[i - tmpLayerEntity.ip - tmp_i].e[1];
                    break;
                }
                tmp_i++;
            }
        }
    }
    else
    {
        anchor_x_f = tmpLayerEntity.ks.a.k_float[0];
        anchor_y_f = tmpLayerEntity.ks.a.k_float[1];
    }
    // 旋转角度
    if (tmpLayerEntity.ks.r.k_entity_num > 0)
    {
        if (i >= tmpLayerEntity.ip && i - tmpLayerEntity.ip < tmpLayerEntity.ks.r.k_entity_num)
        {
            if (tmpLayerEntity.ks.r.k_entity[i-tmpLayerEntity.ip].s_num > 0)
            {
                angle_f = tmpLayerEntity.ks.r.k_entity[i-tmpLayerEntity.ip].s[0] * M_PI / 180.0;
            }
            else
            {
                int tmp_i = 1;
                while (i - tmpLayerEntity.ip - tmp_i >=0)
                {
                    if (tmpLayerEntity.ks.r.k_entity[i-tmpLayerEntity.ip-tmp_i].s_num > 0)
                    {
                        angle_f = tmpLayerEntity.ks.r.k_entity[i-tmpLayerEntity.ip-tmp_i].e[0] * M_PI / 180.0;
                        break;
                    }
                    tmp_i++;
                }
            }
        }
        else
        {
            int tmp_i = 1;
            while (i - tmpLayerEntity.ip - tmp_i >=0)
            {
                if (tmpLayerEntity.ks.r.k_entity[i-tmpLayerEntity.ip-tmp_i].s_num > 0)
                {
                    angle_f = tmpLayerEntity.ks.r.k_entity[i-tmpLayerEntity.ip-tmp_i].e[0] * M_PI / 180.0;
                    break;
                }
                tmp_i++;
            }
        }
    }
    else
    {
        angle_f = tmpLayerEntity.ks.r.k * M_PI / 180.0;
    }
    // 缩放大小，获得值需要除以 100，得到小数
    if (tmpLayerEntity.ks.s.k_entity_num > 0)
    {
        if (i >= tmpLayerEntity.ip && i - tmpLayerEntity.ip < tmpLayerEntity.ks.s.k_entity_num)
        {
            if (tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip].s_num > 0)
            {
                scale_f_x = tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip].s[0]/100.0;
                scale_f_y = tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip].s[1]/100.0;
            }
            else
            {
                int tmp_i = 1;
                while (i - tmpLayerEntity.ip - tmp_i >=0)
                {
                    if (tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip- tmp_i].s_num > 0)
                    {
                        scale_f_x = tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip- tmp_i].e[0]/100.0;
                        scale_f_y = tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip- tmp_i].e[1]/100.0;
                        break;
                    }
                    tmp_i++;
                }
            }
        }
        else
        {
            int tmp_i = 1;
            while (i - tmpLayerEntity.ip - tmp_i >=0)
            {
                if (tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip- tmp_i].s_num > 0)
                {
                    scale_f_x = tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip- tmp_i].e[0]/100.0;
                    scale_f_y = tmpLayerEntity.ks.s.k_entity[i-tmpLayerEntity.ip- tmp_i].e[1]/100.0;
                    break;
                }
                tmp_i++;
            }
        }
    }
    else if (tmpLayerEntity.ks.s.k_float)
    {
        scale_f_x = tmpLayerEntity.ks.s.k_float[0]/100.0;
        scale_f_y = tmpLayerEntity.ks.s.k_float[1]/100.0;
    }
    // 位移，xy轴方向
    if (tmpLayerEntity.ks.p.k_entity_num > 0)
    {
        if (i >= tmpLayerEntity.ip && i - tmpLayerEntity.ip < tmpLayerEntity.ks.p.k_entity_num)
        {
            if (tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip].s_num > 0)
            {
                x_f = tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip].s[0]-anchor_x_f;
                y_f = tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip].s[1]-anchor_y_f;
            }
            else
            {
                int tmp_i = 1;
                while (i - tmpLayerEntity.ip - tmp_i >=0)
                {
                    if (tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip- tmp_i].s_num > 0)
                    {
                        x_f = tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip- tmp_i].e[0]-anchor_x_f;
                        y_f = tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip- tmp_i].e[1]-anchor_y_f;
                        break;
                    }
                    tmp_i++;
                }
            }
        }
        else
        {
            int tmp_i = 1;
            while (i - tmpLayerEntity.ip - tmp_i >=0)
            {
                if (tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip- tmp_i].s_num > 0)
                {
                    x_f = tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip- tmp_i].e[0]-anchor_x_f;
                    y_f = tmpLayerEntity.ks.p.k_entity[i-tmpLayerEntity.ip- tmp_i].e[1]-anchor_y_f;
                    break;
                }
                tmp_i++;
            }
        }
    }
    else
    {
        x_f = tmpLayerEntity.ks.p.k_float[0]-anchor_x_f;
        y_f = tmpLayerEntity.ks.p.k_float[1]-anchor_y_f;
    }
    
    *angle_f_v = angle_f;
    *scale_f_x_v = scale_f_x;
    *scale_f_y_v = scale_f_y;
    *x_f_v = x_f;
    *y_f_v = y_f;
    *anchor_x_f_v = anchor_x_f;
    *anchor_y_f_v = anchor_y_f;
    *alpha_f_v = alpha_f;
}

void ParseAE::parse_mask_layer(char *mask_img_path_str, char *mask_img_ind_str, char *mask_img_ref_id_str, int &mask_count, int total_layernum, AELayerEntity *layers, char *src_config_file_path)
{
    char *tmp_mask_img_path_str = (char *)malloc(sizeof(char) * 100);
    char *tmp_mask_img_ind_str = (char *)malloc(sizeof(char) * 100);
    char *tmp_mask_img_ref_id_str = (char *)malloc(sizeof(char) * 100);
    char *now_pwd = (char *)malloc(sizeof(char) * 1024);
    now_pwd[0] = '\0';
    get_pwd(src_config_file_path, now_pwd);
    int tmp_layer_i = 0;
    for (; tmp_layer_i < total_layernum; ++tmp_layer_i)
    {
        AELayerEntity tmpEntity = layers[tmp_layer_i];
        if (tmpEntity.hasMask)
        {
            const char *firstName = "tp_mask_";
            int midName = tmpEntity.ind;
            const char *lastName = ".png";
            
            char *name = (char *) malloc(strlen(now_pwd) + strlen(firstName) + length_int(midName) + strlen(lastName));
            sprintf(name, "%s%s%d%s",now_pwd, firstName, midName, lastName);
            if (mask_count > 0)
            {
                sprintf(tmp_mask_img_path_str, "%s%s",tmp_mask_img_path_str, "^");
                sprintf(tmp_mask_img_ind_str, "%s%s",tmp_mask_img_ind_str, "^");
                sprintf(tmp_mask_img_ref_id_str, "%s%s",tmp_mask_img_ref_id_str, "^");
            }
            else
            {
                tmp_mask_img_path_str = (char *)malloc(sizeof(char)*1024);
                tmp_mask_img_path_str[0] = '\0';
                tmp_mask_img_ind_str = (char *)malloc(sizeof(char)*1024);
                tmp_mask_img_ind_str[0] = '\0';
                tmp_mask_img_ref_id_str = (char *)malloc(sizeof(char)*1024);
                tmp_mask_img_ref_id_str[0] = '\0';
            }
            sprintf(tmp_mask_img_path_str, "%s%s%c",tmp_mask_img_path_str, name,'\0');
            sprintf(tmp_mask_img_ind_str, "%s%d%c",tmp_mask_img_ind_str, tmpEntity.ind,'\0');
            int tmp_count = 0;
            char **ref_id = NULL;
            ref_id = split(tmpEntity.refId, '_', &tmp_count);
            sprintf(tmp_mask_img_ref_id_str, "%s%s%c",tmp_mask_img_ref_id_str, ref_id[tmp_count-1],'\0');
            strcpy(mask_img_path_str, tmp_mask_img_path_str);
            strcpy(mask_img_ind_str, tmp_mask_img_ind_str);
            strcpy(mask_img_ref_id_str, tmp_mask_img_ref_id_str);
            mask_count++;
        }
    }
}

