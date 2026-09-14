#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPointer;
uniform sampler2D uTextureCurrent;
uniform sampler2D uTextureNext;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uSize;
    float progress = clamp(uPointer, 0.0, 1.0);
    
    // めくりの境目（右から左へ移動）
    float curlPos = 1.0 - progress;
    // 影の幅
    float shadowWidth = 0.08;

    if (st.x < curlPos) {
        // 現在表示中のページ（表）
        // めくり境界線の手前にだけ自然なグラデーション影をつける
        float shadow = smoothstep(curlPos - shadowWidth, curlPos, st.x) * 0.25;
        vec4 color = texture(uTextureCurrent, st);
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    } else {
        // めくった後に現れる次のページ（裏側）
        // 境界線の直下に落とすうっすらとした落ち影
        float shadow = smoothstep(curlPos + shadowWidth, curlPos, st.x) * 0.35;
        vec4 color = texture(uTextureNext, st);
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    }
}
