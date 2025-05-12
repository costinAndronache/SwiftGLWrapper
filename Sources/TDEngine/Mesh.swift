import Foundation

struct Mesh<GLW: GLWrapper> {
    private let program: GLWrapperProgram
    private let vertexBuffer: GLWrapperVertexBuffer
    private let geometry: GLWrapperGeometryDescription

    init(program: GLWrapperProgram,
         vertexBuffer: GLWrapperVertexBuffer,
         geometry: GLWrapperGeometryDescription) {
        self.program = program
        self.vertexBuffer = vertexBuffer
        self.geometry = geometry
    }

    func renderInCurrentContext() {
        program.activate()
        vertexBuffer.activate()
        GLW.glDrawArrays(geometry)
    }
}