// The Swift Programming Language
// https://docs.swift.org/swift-book

import swiftGLFW
import SGLOpenGL
import WinSDK

public let GL: any GLWrapper.Type = SGLOpenGLWrapper.self

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
        GL.glViewport(x: 0, y: 0, width: width, height: height)

        WinSDK.AllocConsole()

        do {

            let mesh = try loadTexturedMesh(SGLOpenGLWrapper.self)

            while glfwWindowShouldClose(window) == GL_FALSE {
                glfwPollEvents()

                GL.glClearColor(red: 0.2, green: 0.3, blue: 0.3, alpha: 1.0)
                GL.glClear(GL_COLOR_BUFFER_BIT)
                
                mesh.renderInCurrentContext()

                glfwSwapBuffers(window)
            }

        } catch {
            print("ERROR: \(error)")
        }

        let _ = readLine()
    }
}
