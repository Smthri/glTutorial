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
uniform sampler2D depthMap;
uniform samplerCube shadowMap;

uniform float height_scale;
uniform float far_plane;

float ShadowCalculation2(vec3 fragPos, vec3 normal, vec3 lightDir) {
    vec3 fragToLight = fragPos - fs_in.TangentLightPos;
    float currentDepth = length(fragToLight);

    float bias = max(0.1 * (1.0 - dot(normal, lightDir)), 0.05);
    float viewDistance = length(fs_in.TangentViewPos - fragPos);
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
        float closestDepth = texture(shadowMap, fragToLight + sampleOffsetDirections[i]*radius).r * far_plane;
        if (currentDepth - bias < closestDepth) {
            ++shadow;
        }
    }
    return shadow / samples;
}

vec2 ParallaxMapping(vec2 texCoords, vec3 viewDir)
{
    const float minLayers = 8.0;
    const float maxLayers = 32.0;
    float numLayers = mix(maxLayers, minLayers, abs(dot(vec3(0.0, 0.0, 1.0), viewDir)));
    float layerDepth = 1.0 / numLayers;
    float currentLayerDepth = 0.0;

    vec2 P = viewDir.xy * height_scale;
    vec2 deltaTexCoords = P / numLayers;

    vec2 currentTexCoords = texCoords;
    float currentDepthMapValue = texture(depthMap, currentTexCoords).r;

    while (currentLayerDepth < currentDepthMapValue) {
        currentTexCoords -= deltaTexCoords;
        currentDepthMapValue = texture(depthMap, currentTexCoords).r;
        currentLayerDepth += layerDepth;
    }

    vec2 prevTexCoords = currentTexCoords + deltaTexCoords;

    float afterDepth = currentDepthMapValue - currentLayerDepth;
    float beforeDepth = texture(depthMap, prevTexCoords).r - currentLayerDepth + layerDepth;

    float weight = afterDepth / (afterDepth - beforeDepth);
    vec2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

    return finalTexCoords;
}

const float y = 0.4;

void main()
{
    vec3 viewDir = normalize(fs_in.TangentViewPos - fs_in.TangentFragPos);
    vec2 texCoords = ParallaxMapping(fs_in.TexCoords,  viewDir);

    vec3 lightDir = normalize(fs_in.TangentLightPos - fs_in.TangentFragPos);

    vec3 diffuse = texture(diffuseMap, texCoords).rgb;
    vec3 normal = texture(normalMap, texCoords).rgb;
    normal = normalize(normal * 2.0 - 1.0);

    vec3 ambient = diffuse * 0.2;
    float diff = max(dot(lightDir, normal), 0.0);
    diffuse = diffuse * diff;

    vec3 result = ambient + diffuse;

    float deltay = y - fs_in.TangentFragPos.y;
    if (deltay > 0.0) {
        vec3 fogColor = vec3(0.5, 0.6, 0.7);
        float density = 0.1;
        float l;
        float fogAmount = 0.0;
        if (fs_in.TangentViewPos.y <= y) {
            l = length(fs_in.TangentViewPos - fs_in.TangentFragPos);
            fogAmount = l * density;
        } else {
            float angle = dot(vec3(0.0, 1.0, 0.0), viewDir);
            fogAmount = deltay / angle * density;
        }
        fogAmount = clamp(fogAmount, 0.0, 0.3);

        result = mix(result, fogColor, fogAmount);
    }
    FragColor = vec4(result, 1.0);
}