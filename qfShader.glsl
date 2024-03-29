#version 330
out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D screenTexture;
uniform int gauss;

const float offset = 1.0 / 300.0;

void main() {
    vec2 offsets[9] = vec2[] (
        vec2(-offset, offset),
        vec2(0.0, offset),
        vec2(offset, offset),

        vec2(-offset, 0.0),
        vec2(0.0, 0.0),
        vec2(offset, 0.0),

        vec2(-offset, -offset),
        vec2(0.0, -offset),
        vec2(offset, -offset)
    );

    float kernel[9] = float[] (
        1, 1, 1,
        1, -8, 1,
        1, 1, 1
    );

    vec3 sampleTex[9];
    for (int i = 0; i < 9; ++i) {
        sampleTex[i] = vec3(texture(screenTexture, TexCoords.st + offsets[i]));
    }

    vec3 col = vec3(0.0);
    for (int i = 0; i < 9; ++i) {
        col += sampleTex[i] * kernel[i];
    }

    if (gauss == 1) {
        FragColor = vec4(col, 1.0);
    } else {
        FragColor = texture(screenTexture, TexCoords);
    }
}
