
//接收来自顶点着色器的纹理坐标
varying lowp vec2 varyTextCoord;
//纹理取样器
uniform sampler2D colorMap;

void main()
{
    // texture2D 读取纹素
    lowp vec4 tex = texture2D(colorMap, vec2(varyTextCoord.x,1.0-varyTextCoord.y));
    //纹素 * 颜色 赋值给内建变量gl_FragColor
    gl_FragColor = tex ;
}
