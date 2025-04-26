// The Swift Programming Language
// https://docs.swift.org/swift-book

import swiftGLFW
import SGLOpenGL

@main
struct Main {
    static func main() {
        let width: Int32 = 800
        let height: Int32 = 600
        glfwInit()
        defer { glfwTerminate() }
    
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3)
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
        glfwWindowHint(GLFW_RESIZABLE, GL_FALSE)
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE)

        guard let window = glfwCreateWindow(width, height, "LearnSwiftGL", nil, nil) else {
            print("Failed to create GLFW window")
            return
        }

        glfwMakeContextCurrent(window)
        glViewport(x: 0, y: 0, width: width, height: height)

        while glfwWindowShouldClose(window) == GL_FALSE
        {
            glfwPollEvents()

            glClearColor(red: 0.2, green: 0.3, blue: 0.3, alpha: 1.0)
            glClear(GL_COLOR_BUFFER_BIT)
    
            glfwSwapBuffers(window)
        }
    }
}
