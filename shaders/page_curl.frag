#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress; // 0.0 ~ 1.0 めくり進行度
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uSize;
    
    // カールの半径と角度計算
    float aspect = uSize.x / uSize.y;
    vec2 uv = st;
    
    float angle = 30.0 * 3.14159265 / 180.0;
    vec2 dir = vec2(cos(angle), sin(angle));
    
    float radius = 0.15;
    float amount = uProgress * 1.5;
    
    float d = dot(uv - vec2(1.0, 1.0), dir) + amount;
    
    if (d < 0.0) {
        // 通常の表面描画
        fragColor = texture(uTexture, uv);
    } else if (d < 3.14159265 * radius) {
        // カール（折り返しの曲面）計算
        float mapAngle = d / radius;
        float shadow = sin(mapAngle);
        vec2 curlUv = uv - dir * (d - sin(mapAngle) * radius);
        
        vec4 texColor = texture(uTexture, curlUv);
        // 裏面の影とグラデーションの付与
        fragColor = mix(texColor * 0.6, vec4(0.0, 0.0, 0.0, 0.4), shadow * 0.5);
    } else {
        // めくられて消える部分（透過）
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
