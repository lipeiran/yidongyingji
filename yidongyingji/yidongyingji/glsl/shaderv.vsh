//四维向量 顶点坐标
attribute vec4 position;
//二维向量 纹理坐标
attribute vec2 textCoordinate;
//低精度二维向量 纹理坐标
/*
 此处用varying 修饰，表示要通过这个变量，将纹理坐标传递给片元着色器
 lowp表示低精度
 精度可分为highp/mediump/lowp 分别对应高/中/低
 
 ****************************************
 此处声明变量的方式，以及变量名。
 在片元着色器中，要同样声明一个一模一样的，才能完成纹理坐标的传递。
 ****************************************
 */
varying lowp vec2 varyTextCoord;
void main(){
    //varying 修饰，将纹理坐标传递到片元着色器
    varyTextCoord = textCoordinate;
    //给内建变量赋值
    gl_Position = position;
}
