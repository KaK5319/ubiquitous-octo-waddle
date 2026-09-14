#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPointer; // 0.0 ~ 1.0 (めくり進行度)
uniform sampler2D uTextureCurrent;
uniform sampler2D uTextureNext;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uSize;
    float aspect = uSize.x / uSize.y;
    
    // 右開き（漫画）用のめくり位置計算
    float progress = clamp(uPointer, 0.0, 1.0);
    float angle = 30.0 * 3.14159265 / 180.0;
    vec2 dir = vec2(cos(angle), sin(angle));
    
    vec2 origin = vec2(progress * (1.0 + dir.x), 0.0);
    vec2 p = st - origin;
    float d = dot(p, dir);

    if (d > 0.0) {
        // めくられてめくれ上がっている部分（裏面）
        float radius = 0.15; // 円筒の太さ
        if (d < radius * 3.14159265) {
            float shadow = sin(d / radius) * 0.4;
            vec2 backSt = st - dir * d * 2.0;
            vec4 color = texture(uTextureCurrent, backSt);
            // 裏面っぽく少し暗くする
            fragColor = vec4(color.rgb * (0.6 + shadow), color.a);
        } else {
            // 下に隠れている次のページ
            fragColor = texture(uTextureNext, st);
        }
    } else {
        // まだめくられていない現在のページ
        float shadow = smoothstep(-0.2, 0.0, d) * 0.3;
        vec4 color = texture(uTextureCurrent, st);
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    }
}
