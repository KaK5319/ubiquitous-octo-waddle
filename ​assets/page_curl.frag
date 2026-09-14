#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPointer;
uniform sampler2D uTextureCurrent;
uniform sampler2D uTextureNext;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uSize;
    float progress = clamp(uPointer, 0.0, 1.0);
    
    // 30度をラジアンに変換
    float angle = 0.52359877559; 
    vec2 dir = vec2(cos(angle), sin(angle));
    
    vec2 origin = vec2(progress * (1.0 + dir.x), 0.0);
    vec2 p = st - origin;
    float d = dot(p, dir);

    if (d > 0.0) {
        float radius = 0.15;
        if (d < radius * 3.14159265359) {
            float shadow = sin(d / radius) * 0.4;
            vec2 backSt = st - dir * d * 2.0;
            vec4 color = texture(uTextureCurrent, backSt);
            fragColor = vec4(color.rgb * (0.6 + shadow), color.a);
        } else {
            fragColor = texture(uTextureNext, st);
        }
    } else {
        float shadow = smoothstep(-0.2, 0.0, d) * 0.3;
        vec4 color = texture(uTextureCurrent, st);
        fragColor = vec4(color.rgb * (1.0 - shadow), color.a);
    }
}
