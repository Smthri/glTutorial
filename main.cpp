#include <iostream>
#include <cstdio>
#include <string>
#include <fstream>
#include <streambuf>
#include <cstdlib>

#include <glad/glad.h>
#include "glad.c"
#include <GLFW/glfw3.h>
#include <sstream>
#include <cmath>

float vertices[] = {
        0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f,
        -0.5f, -0.5f, 0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.5f, 0.0f, 0.0f, 0.0f, 1.0f
};
unsigned int indices[] = {
        0, 1, 3,
        1, 2, 3
};

const unsigned int BUFFSIZE = 512;

char *fragmentShaderSource;
char *vertexShaderSource;

void framebuffer_size_callback(GLFWwindow *w, int width, int height) {
    glViewport(0, 0, width, height);
}

void processInput(GLFWwindow* w) {
    if (glfwGetKey(w, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
        glfwSetWindowShouldClose(w, true);
    }
}

unsigned int initShaders() {

    std::ifstream vertexdata("../vertexShaderSource.glsl");
    std::stringstream buffer1;
    buffer1 << vertexdata.rdbuf();
    vertexShaderSource = new char [500];
    strcpy(vertexShaderSource, buffer1.str().c_str());
    buffer1.str(std::string());

    std::ifstream fragmentdata("../fragmentShaderSource.glsl");
    buffer1 << fragmentdata.rdbuf();
    fragmentShaderSource = new char [500];
    strcpy(fragmentShaderSource, buffer1.str().c_str());

    /* Set up and compile shaders */
    // vertex shader
    unsigned int vertexShader;
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);
    //check for success
    int success;
    char infoLog[BUFFSIZE];
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(vertexShader, BUFFSIZE, NULL, infoLog);
        std::cout << "Vertex shader compilation error: " << infoLog << std::endl;
    }
    // fragment shader
    unsigned int fragmentShader;
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);
    //check for success
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragmentShader, BUFFSIZE, NULL, infoLog);
        std::cout << "Fragment shader compilation error: " << infoLog << std::endl;
    }

    /* Create shader program */
    unsigned int shaderProgram;
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    // check success
    glGetShaderiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shaderProgram, BUFFSIZE, NULL, infoLog);
        std::cout << "Linker error: " << infoLog << std::endl;
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    return shaderProgram;
}

unsigned int bufferSetup() {
    /* Set up vertex data and buffers */
    unsigned int VBO, VAO, EBO;
    glGenBuffers(1, &VBO);
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &EBO);
    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    //glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), nullptr);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void *) (3* sizeof(float)));
    glEnableVertexAttribArray(1);

    return VAO;
}

int main() {

    /* Initialize and configure GLFW */
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    /* Create GLFW window */
    GLFWwindow* window = glfwCreateWindow(800, 600, "Learn OpenGL", NULL, NULL);
    if (!window) {
        fprintf(stderr, "Failed to create GLFW window");
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    /* glad: Load all OpenGL function pointers */
    if (!gladLoadGLLoader((GLADloadproc) glfwGetProcAddress)) {
        fprintf(stderr, "Failed to initialize GLAD");
        glfwTerminate();
        return -1;
    }

    unsigned int VAO = bufferSetup();
    unsigned int shaderProgram = initShaders();

    //glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); // wireframe
    float timeValue, greenValue;
    int vertexColorLocation;
    while (!glfwWindowShouldClose(window)) {
        processInput(window);

        // rendering here
        glClearColor(0.2f, 0.3f, 0.3f, 0.1f);
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shaderProgram);

        timeValue = (float) glfwGetTime();
        greenValue = ((float) sin(timeValue) / 2.0f) + 0.5f;
        vertexColorLocation = glGetUniformLocation(shaderProgram, "ourColor");
        glUniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);
        glBindVertexArray(VAO);
        //glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}