#version 330

out vec4 FragColor;

in VS_OUT {
    vec3 Normal;
    vec3 FragPos;
    vec2 TexCoords;
} fs_in;

const float PI = 3.14159265359;

uniform vec3 viewPos;
uniform vec3 lightPos;
uniform sampler2D gold;

float D(float alpha, float m, vec3 normal, vec3 halfway) {
    float nh = dot(normal, halfway);
    return exp((nh*nh - 1) / (m*m*nh*nh)) / (m*m * pow(nh, 4));
}

const float roughness = 0.3;
const float metallic = 1.0;

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

vec3 fresnelShlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0)*pow(1.0 - cosTheta, 5.0);
}

const float y = 0.4;

void main() {
    vec3 I = texture(gold, fs_in.TexCoords).rgb * 0.2;
    vec3 F0 = vec3(1.00, 0.71, 0.29); // gold

    vec3 N = normalize(fs_in.Normal);
    vec3 V = normalize(viewPos - fs_in.FragPos);
    vec3 L = normalize(lightPos - fs_in.FragPos);
    vec3 H = normalize(V + L);

    float distance = length(lightPos - fs_in.FragPos);
    //float attenuation = 1.0;
    float attenuation = 1.0 / (0.1 * distance * distance);
    vec3 radiance = vec3(1.0) * attenuation;

    vec3 F = fresnelShlick(max(dot(H, V), 0.0), F0);
    float NDF = DistributionGGX(N, H, roughness);
    float G = GeometrySmith(N, V, L, roughness);
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
    vec3 specular = NDF * G * F / max(denominator, 0.001);

    vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);

    float NdotL = max(dot(N, L), 0.0);
    I += I * NdotL * 10.0;

    I += (kD / PI + specular) * radiance * NdotL;

    float deltay = y - fs_in.FragPos.y;
    if (deltay > 0.0) {
        vec3 fogColor = vec3(0.5, 0.6, 0.7);
        float density = 0.1;
        float l;
        float fogAmount = 0.0;
        if (viewPos.y <= y) {
            l = length(viewPos - fs_in.FragPos);
            fogAmount = l * density;
        } else {
            float angle = dot(vec3(0.0, 1.0, 0.0), V);
            fogAmount = deltay / angle * density;
        }
        fogAmount = clamp(fogAmount, 0.0, 0.3);

        I = mix(I, fogColor, fogAmount);
    }

    FragColor = vec4(I, 1.0);

//    vec3 normal = normalize(fs_in.Normal);
//    vec3 lightDir = normalize(fs_in.FragPos - lightPos);
//    vec3 viewDir = normalize(fs_in.FragPos - viewPos);
//    float G = min(1, 2 * dot(normal, lightDir) / dot(normal, viewDir));
//
//    FragColor = vec4(I * G * F0 * D(0.1, 2.0, normal, normal) / (4.0 * dot(normal, lightDir) * dot(normal, viewDir)), 1.0);
}
