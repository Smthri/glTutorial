cmake_minimum_required(VERSION 3.15)
project(gltutorial)

set(CMAKE_CXX_STANDARD 17)

add_executable(gltutorial main.cpp)
target_link_libraries(gltutorial m glut GLEW GL GLU glfw3 pthread Xi X11 Xxf86vm Xrandr ${CMAKE_DL_LIBS})