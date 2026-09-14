#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPointer;
uniform sampler2D uTextureCurrent;
uniform sampler2D uTextureNext;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uSize;
    float progress = clamp(uPointer, 0.0, 1.0);
    
    // めくるページの右端の位置（1.0 から 0.0 へ動く）
    float curlPos = 1.0 - progress;
    float shadowWidth = 0.1;

    // めくっている最中のページ（現在のページ）がスライドして隠れる範囲
    if (st.x < curlPos) {
        // 上に載っている現在のページ
        vec4 color = texture(uTextureCurrent, st);
        // めくり端の直前にうっすら陰影をつける
        float shadow = smoothstep(curlPos - shadowWidth, curlPos, st.x) * 0.3;
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    } else {
        // 下に敷かれている次のページ（めくった部分から露出する）
        vec4 color = texture(uTextureNext, st);
        // 上のページが落とす影を計算
        float shadow = (1.0 - smoothstep(curlPos, curlPos + shadowWidth, st.x)) * 0.4;
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    }
}
