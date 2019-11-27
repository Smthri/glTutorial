#version 330 core
#define NR_POINT_LIGHTS 1
out vec4 FragColor;

uniform vec3 lightPos;
uniform vec3 viewPos;
uniform samplerCube shadowMap;
uniform float far_plane;

in VS_OUT {
    vec3 Normal;
    vec3 FragPos;
    vec2 TexCoords;
} fs_in;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

struct DirLight {
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {
    vec3 position;

    float constant;
    float linear;
    float quadratic;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform DirLight dirLight;
uniform PointLight pointLight[NR_POINT_LIGHTS];
uniform Material material;
/*
float ShadowCalculation(vec4 fragPosLightSpace, vec3 normal, vec3 lightDir) {
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5;
    float ClosestDepth = texture(shadowMap, projCoords.xy).r;
    float currentDepth = projCoords.z;
    float bias = max(0.05 * (1.0 - dot(normal, lightDir)), 0.05);

    float shadow = 0.0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            float pcfDepth = texture(shadowMap, projCoords.xy + vec2(x, y)*texelSize).r;
            shadow += (currentDepth - bias > pcfDepth ? 0.0 : 1.0);
        }
    }
    shadow /= 9.0;
    return shadow;
}
*/
float ShadowCalculation2(vec3 fragPos, vec3 normal, vec3 lightDir) {
    vec3 fragToLight = fragPos - pointLight[0].position;
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
        float closestDepth = texture(shadowMap, fragToLight + sampleOffsetDirections[i]*radius).r * far_plane;
        if (currentDepth - bias < closestDepth) {
            ++shadow;
        }
    }
    return shadow / samples;
}

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 lightDir = normalize(light.position - fragPos);

    float diff = max(dot(normal, lightDir), 0.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(reflectDir, viewDir), 0.0), material.shininess);

    float distance = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * distance * distance);

    vec3 ambient = light.ambient * vec3(texture(material.diffuse, fs_in.TexCoords));
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, fs_in.TexCoords));
    vec3 specular = light.specular * spec * vec3(texture(material.specular, fs_in.TexCoords));

    float shadow = ShadowCalculation2(fs_in.FragPos, normal, lightDir);
    //float shadow = ShadowCalculation(fs_in.FragPosLightSpace, normal, lightDir);
    return (ambient + (diffuse + specular) * shadow) * attenuation;
}

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(-light.direction);
    float diff = max(dot(normal, lightDir), 0.0);

    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    vec3 ambient = light.ambient * vec3(texture(material.diffuse, fs_in.TexCoords));
    vec3 diffuse = light.diffuse * vec3(texture(material.diffuse, fs_in.TexCoords));
    vec3 specular = light.specular * vec3(texture(material.specular, fs_in.TexCoords));

    float shadow;
    return ambient + shadow * (diffuse + specular);
}

const float y = 0.4;

void main() {
    vec3 norm = normalize(fs_in.Normal);
    vec3 viewDir = normalize(viewPos - fs_in.FragPos);
    //vec3 result = CalcDirLight(dirLight, norm, viewDir);
    vec3 result = CalcPointLight(pointLight[0], norm, fs_in.FragPos, viewDir);

    float deltay = y - fs_in.FragPos.y;
    if (deltay > 0.0) {
        vec3 fogColor = vec3(0.5, 0.6, 0.7);
        float density = 0.1;
        float angle = max(dot(vec3(0.0, 1.0, 0.0), viewDir), dot(vec3(0.0, -1.0, 0.0), viewDir));
        float fogAmount = clamp(deltay / angle * density, 0.0, 0.3);

        result = mix(result, fogColor, fogAmount);
    }

    FragColor = vec4(result, 1.0);
}
