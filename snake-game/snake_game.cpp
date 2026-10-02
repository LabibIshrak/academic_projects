#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>

const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 800;

const int GRID_SIZE = 20;
const int CELL_SIZE = SCR_WIDTH / GRID_SIZE;

enum Direction { UP, DOWN, LEFT, RIGHT };
Direction dir = RIGHT;

struct Point {
    int x, y;
};

std::vector<Point> snake = { {10, 10} };
Point food = { rand() % GRID_SIZE, rand() % GRID_SIZE };

float vertices[] = {
    // Square (x, y)
    0.0f, 0.0f,
    1.0f, 0.0f,
    1.0f, 1.0f,
    0.0f, 1.0f
};

unsigned int indices[] = {
    0, 1, 2,
    2, 3, 0
};

const char* vertexShaderSource = R"(
#version 330 core
layout (location = 0) in vec2 aPos;
uniform vec2 offset;
uniform float scale;
void main()
{
    vec2 pos = (aPos + offset) * scale * 2.0 - 1.0;
    pos.y = -pos.y;
    gl_Position = vec4(pos, 0.0, 1.0);
}
)";

const char* fragmentShaderSource = R"(
#version 330 core
out vec4 FragColor;
uniform vec3 color;
void main()
{
    FragColor = vec4(color, 1.0);
}
)";

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
}

void processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS && dir != DOWN)
        dir = UP;
    if (glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS && dir != UP)
        dir = DOWN;
    if (glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS && dir != RIGHT)
        dir = LEFT;
    if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS && dir != LEFT)
        dir = RIGHT;
}

void moveSnake()
{
    Point head = snake[0];
    if (dir == UP) head.y--;
    else if (dir == DOWN) head.y++;
    else if (dir == LEFT) head.x--;
    else if (dir == RIGHT) head.x++;

    if (head.x < 0 || head.y < 0 || head.x >= GRID_SIZE || head.y >= GRID_SIZE)
    {
        std::cout << "Game Over: Hit Wall\n";
        exit(0);
    }

    for (auto& s : snake)
        if (s.x == head.x && s.y == head.y)
        {
            std::cout << "Game Over: Hit Self\n";
            exit(0);
        }

    snake.insert(snake.begin(), head);
    if (head.x == food.x && head.y == food.y)
    {
        food = { rand() % GRID_SIZE, rand() % GRID_SIZE };
    }
    else
    {
        snake.pop_back();
    }
}

int main()
{
    srand(time(0));
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Snake Game", NULL, NULL);
    if (!window)
    {
        std::cerr << "Failed to create window\n";
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    // Shader setup
    unsigned int vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, nullptr);
    glCompileShader(vertexShader);

    unsigned int fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, nullptr);
    glCompileShader(fragmentShader);

    unsigned int shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    unsigned int VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    glUseProgram(shaderProgram);
    int offsetLoc = glGetUniformLocation(shaderProgram, "offset");
    int scaleLoc = glGetUniformLocation(shaderProgram, "scale");
    int colorLoc = glGetUniformLocation(shaderProgram, "color");

    float scale = 1.0f / GRID_SIZE;

    double lastTime = glfwGetTime();
    double timer = 0;
    double delay = 0.2;

    while (!glfwWindowShouldClose(window))
    {
        double currentTime = glfwGetTime();
        if (currentTime - lastTime >= delay)
        {
            moveSnake();
            lastTime = currentTime;
        }

        processInput(window);
        glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        glBindVertexArray(VAO);
        glUseProgram(shaderProgram);
        glUniform1f(scaleLoc, scale);

        // Draw food
        glUniform2f(offsetLoc, (float)food.x, (float)food.y);
        glUniform3f(colorLoc, 1.0f, 0.0f, 0.0f); // red
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        // Draw snake
        for (size_t i = 0; i < snake.size(); ++i)
        {
            glUniform2f(offsetLoc, (float)snake[i].x, (float)snake[i].y);
            glUniform3f(colorLoc, 0.0f, 1.0f, 0.0f); // green
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
        }

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}
