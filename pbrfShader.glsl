#version 330

out vec4 FragColor;

in VS_OUT {
    vec3 Normal;
    vec3 FragPos;
    vec2 TexCoords;
} fs_in;

uniform vec3 viewPos;
uniform vec3 lightPos;
uniform sampler2D gold;

float D(float alpha, float m, vec3 normal, vec3 halfway) {
    float nh = dot(normal, halfway);
    return exp((nh*nh - 1) / (m*m*nh*nh)) / (m*m * pow(nh, 4));
}

void main() {
    vec3 I = texture(gold, fs_in.TexCoords).rgb;
    vec3 F0 = vec3(1.00, 0.71, 0.29); // gold
    vec3 normal = normalize(fs_in.Normal);
    vec3 lightDir = normalize(fs_in.FragPos - lightPos);
    vec3 viewDir = normalize(fs_in.FragPos - viewPos);
    float G = min(1, 2 * dot(normal, lightDir) / dot(normal, viewDir));

    FragColor = vec4(I * G * F0 * D(0.1, 2.0, normal, normal) / (4.0 * dot(normal, lightDir) * dot(normal, viewDir)), 1.0);
}
