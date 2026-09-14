#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPointer;
uniform sampler2D uTextureCurrent;
uniform sampler2D uTextureNext;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uSize;
    float progress = clamp(uPointer, 0.0, 1.0);
    
    // めくりの境目を右から左へ移動（水平めくり）
    float curlPos = 1.0 - progress;
    float radius = 0.08; // めくりの丸み・筒の太さ

    if (st.x < curlPos) {
        // まだめくられていない表面
        // 右端が近づくにつれてほんのり影をつける
        float shadow = smoothstep(curlPos - 0.15, curlPos, st.x) * 0.2;
        vec4 color = texture(uTextureCurrent, st);
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    } else if (st.x < curlPos + radius * 3.14159265) {
        // めくれているカール部分（裏面が回り込む）
        float d = st.x - curlPos;
        float shadow = sin(d / radius) * 0.35; // カールの立体感を生む影
        
        // 裏返った表面のテクスチャを正しく反転表示
        vec2 backSt = vec2(curlPos - d, st.y);
        vec4 color = texture(uTextureCurrent, backSt);
        
        // 裏面らしく少し暗く表示
        fragColor = vec4(color.rgb * (0.65 + shadow), color.a);
    } else {
        // めくった後に見えてくる次のページ
        // めくりの下に落ちる影を計算
        float shadow = smoothstep(curlPos + radius * 3.14159265 + 0.1, curlPos + radius * 3.14159265, st.x) * 0.3;
        vec4 color = texture(uTextureNext, st);
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    }
}
