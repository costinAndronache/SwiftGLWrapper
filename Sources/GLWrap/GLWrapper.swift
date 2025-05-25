public protocol GLWrapperVertexBuffer {
    func upload(data: UnsafeRawBufferPointer, 
                describedAs descriptions: [GLWrapperAttributeDescriptor],
                hint: GLWrapperUpdateHint) throws (GLWrapperErrors.VertexBufferObjectError) -> Void
    func activate()
}



public protocol GLWrapperProgram {
    func bindVec1iUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<GLint>
    func bindVec1fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<GLfloat>
    func bindVec2fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec2f>
    func bindVec3fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec3f>
    func bindVec4fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec4f>
    func bindMat4fUniform(named: String, inRowOrder: Bool) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Mat4f>

    func activate()
}

public protocol GLWrapperTexture2D {
    func activateOn(index: GLint)
}

public protocol GLWrapper {
    static func createProgramWith(vertexShaderSource: String, 
                                  fragmentShaderSource: String) 
                                  throws (GLWrapperErrors.ProgramError)-> (any GLWrapperProgram)
    
    static func createVertexBuffer() -> (any GLWrapperVertexBuffer)
    static func createTexture2D(width: GLint, 
                                height: GLint, 
                                mipMapStages: GLint, 
                                format: GLWrapperColorFormat, 
                                data: UnsafeRawPointer) -> (any GLWrapperTexture2D)
    static func glDrawArrays(_ geometry: GLWrapperGeometryDescription)
    static func glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei)
    static func glClearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
    static func glClear(_ mask: GLbitfield)
}