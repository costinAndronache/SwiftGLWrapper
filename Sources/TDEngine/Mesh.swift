import Foundation

struct Mesh<GLW: GLWrapper> {
    private let program: GLWrapperProgram
    private let vertexBuffer: GLWrapperVertexBuffer
    private let geometry: GLWrapperGeometryDescription
    private let textures: [GLWrapperTexture2D]

    init(program: GLWrapperProgram,
         vertexBuffer: GLWrapperVertexBuffer,
         geometry: GLWrapperGeometryDescription,
         textures: [GLWrapperTexture2D] = []) {
        self.program = program
        self.vertexBuffer = vertexBuffer
        self.geometry = geometry
        self.textures = textures
    }

    func renderInCurrentContext() {
        for index in 0..<textures.count {
            textures[index].activateOn(index: GLint(index))
        }
        program.activate()
        vertexBuffer.activate()
        GLW.glDrawArrays(geometry)
    }
}