#version 330
out vec4 FragColor;

in vec2 TexCoords;
in vec3 FragPos;

uniform sampler2D texture1;
uniform vec3 viewPos;
uniform vec3 lightPos;

void main() {
    vec3 res = texture(texture1, TexCoords).rgb;

    FragColor = vec4(res, 0.3);
}
