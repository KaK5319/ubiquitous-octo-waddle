#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPointer;
uniform sampler2D uTextureCurrent;
uniform sampler2D uTextureNext;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uSize;
    float progress = clamp(uPointer, 0.0, 1.0);
    
    // スライドして左へ抜けていく「現在のページ」の右端位置（1.0 -> 0.0）
    float edgePos = 1.0 - progress;
    float shadowWidth = 0.12;

    if (st.x < edgePos) {
        // 【上層】左へスライド中の「現在のページ」
        vec4 color = texture(uTextureCurrent, st);
        
        // ページの右端（めくり目）に近づくにつれて立体感の影を入れる
        float shadow = smoothstep(edgePos - shadowWidth, edgePos, st.x) * 0.25;
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    } else {
        // 【下層】右側から露出して見えてくる「次のページ」
        vec4 color = texture(uTextureNext, st);
        
        // 上のページが落とす落ち影を計算
        float shadow = (1.0 - smoothstep(edgePos, edgePos + shadowWidth, st.x)) * 0.4;
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    }
}
