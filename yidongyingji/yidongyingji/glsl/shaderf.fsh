//纹理坐标
varying lowp vec2 varyTextCoord;
//纹理采样器
uniform sampler2D colorMap;
void main(){
    /*
     texture2D(纹理采样器,纹理坐标)
     这个方法可以获取坐标对应的纹素
     
     gl_FragColor 是GLSL的内建变量，用来将纹理颜色添加到对应的像素点上
     */
    
//    gl_FragColor = texture2D(colorMap, varyTextCoord);
       gl_FragColor = texture2D(colorMap, vec2(varyTextCoord.x,1.0-varyTextCoord.y));
}
