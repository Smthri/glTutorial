#version 330
out vec4 FragColor;

in VS_OUT {
    vec3 FragPos;
    vec2 TexCoords;
    vec3 TangentLightPos;
    vec3 TangentViewPos;
    vec3 TangentFragPos;
} fs_in;

uniform sampler2D diffuseMap;
uniform sampler2D normalMap;
uniform samplerCube depthMap;

uniform vec3 lightPos;
uniform vec3 viewPos;

uniform float far_plane;

float ShadowCalculation2(vec3 fragPos, vec3 normal, vec3 lightDir) {
    vec3 fragToLight = fragPos - lightPos;
    float currentDepth = length(fragToLight);

    float bias = max(0.1 * (1.0 - dot(normal, lightDir)), 0.05);
    float viewDistance = length(viewPos - fragPos);
    //float bias = 0.005 * tan(acos(dot(normal, lightDir)));
    bias = clamp(bias, 0.0, 0.2);
    //float shadow = currentDepth - bias > closestDepth ? 0.0 : 1.0;
    float shadow = 0.0;

    int samples = 20;
    vec3 sampleOffsetDirections[20] = vec3[]
    (
    vec3(1, 1, 1), vec3(1, -1, 1), vec3(-1, -1,  1), vec3(-1, 1, 1),
    vec3(1, 1, -1), vec3(1, -1, -1), vec3(-1, -1, -1), vec3(-1, 1, -1),
    vec3(1, 1, 0), vec3(1, -1, 0), vec3(-1, -1,  0), vec3(-1, 1, 0),
    vec3(1, 0, 1), vec3(-1, 0, 1), vec3( 1,  0, -1), vec3(-1, 0, -1),
    vec3(0, 1, 1), vec3(0, -1, 1), vec3( 0, -1, -1), vec3( 0, 1, -1)
    );
    float offset = 0.1;
    float radius = (1.0 + (viewDistance / far_plane)) / 25.0;
    for (int i = 0; i < samples; ++i) {
        float closestDepth = texture(depthMap, fragToLight + sampleOffsetDirections[i]*radius).r * far_plane;
        if (currentDepth - bias < closestDepth) {
            ++shadow;
        }
    }
    return shadow / samples;
}

void main() {
    vec3 normal = texture(normalMap, fs_in.TexCoords).rgb;
    normal = normalize(normal * 2.0 - 1.0);

    vec3 color = texture(diffuseMap, fs_in.TexCoords).rgb;
    vec3 ambient = 0.2 * color;

    vec3 lightDir = normalize(fs_in.TangentLightPos - fs_in.TangentFragPos);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * color;

    vec3 viewDir = normalize(fs_in.TangentViewPos - fs_in.TangentFragPos);
    vec3 reflectDir = reflect(-lightDir, normal);
    vec3 halfwayDir = normalize(viewDir + lightDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), 32.0);

    vec3 specular = vec3(0.2) * spec;
    float shadow = ShadowCalculation2(fs_in.FragPos, normal, lightDir);

    float d = length(lightPos - viewPos);
    float attenuation = 1.0 / (1.0 + d * 0.2 + d*d*0.05);

    vec3 result = (ambient + (diffuse + specular) * shadow) * attenuation;
    vec3 fogColor = vec3(0.5, 0.6, 0.7);
    float distance = length(viewPos - fs_in.FragPos);
    float fogAmount = 1.0 - exp(-distance * 0.01);
    result = mix(result, fogColor, fogAmount);

    FragColor = vec4(result, 1.0);
}
