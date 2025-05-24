import SGLOpenGL

public enum SGLOpenGLWrapper: GLWrapper {
    public typealias VertexShaderIdentifier = GLuint
    public typealias FragmentShaderIdentifier = GLuint
    public typealias ProgramIdentifier = GLuint
    public typealias VertexArrayObjectIdentifier = GLuint
    public typealias VertexBufferIdentifier = GLuint

    public static func glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) {
        SGLOpenGL.glViewport(x: x, y: y, width: width, height: height)
    }

    public static func glClearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {
        SGLOpenGL.glClearColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static func glClear(_ mask: GLbitfield) {
        SGLOpenGL.glClear(mask)
    }

    public static func glDrawArrays(_ geometry: GLWrapperGeometryDescription) {
        SGLOpenGL.glDrawArrays(geometry.drawMode.enumValue, 0, GLsizei(geometry.vertexCount))
    }

    public static func createProgramWith(vertexShaderSource: String, 
                                         fragmentShaderSource: String) 
                                         throws (GLWrapperErrors.ProgramError)-> (any GLWrapperProgram) {
        let id = SGLOpenGL.glCreateProgram()
        let vertexShaderID = try createShader(type: GL_VERTEX_SHADER, source: vertexShaderSource)
        let fragmentShaderID = try createShader(type: GL_FRAGMENT_SHADER, source: fragmentShaderSource)

        glAttachShader(id, vertexShaderID)
        glAttachShader(id, fragmentShaderID)
        glLinkProgram(id)

        var success: GLint = 0
        glGetProgramiv(id, GL_LINK_STATUS, &success)
        if (success == 0) {
            var info: [GLchar] = .init(unsafeUninitializedCapacity: 512) { buffer, initializedCount in
                initializedCount = 0
            }
            glGetProgramInfoLog(id, 512, nil, &info)
            let infoChars = info.map({ Character(Unicode.Scalar(UInt8($0))) })
            let reason = String(infoChars)
            throw(.init(type: .programLink, reason: reason))
        }
        glDeleteShader(vertexShaderID)
        glDeleteShader(fragmentShaderID)
        
        return Program(id: id)
    }

    public static func createVertexBuffer() -> (any GLWrapperVertexBuffer) { VertexBuffer() }
    public static func createTexture2D(width: GLint, 
                                       height: GLint, 
                                       mipMapStages: GLint, 
                                       format: GLWrapperColorFormat, 
                                       data: UnsafeRawPointer) -> (any GLWrapperTexture2D) {
        
        var texture: GLuint = 0
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        // set the texture wrapping/filtering options (on the currently bound texture object)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glTexImage2D(GL_TEXTURE_2D, mipMapStages, format.glEnumValue, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);

        return Texture2D(id: texture)
    }
}


private extension SGLOpenGLWrapper {
    static func createShader(type: GLenum, source: String) throws(GLWrapperErrors.ProgramError) -> GLuint {
        let id = glCreateShader(type)
        source.withCString { ptr in
            var array: [UnsafePointer<Int8>] = [ptr]
            glShaderSource(id, 1, &array, nil)
        }
        glCompileShader(id)

        var success: GLint = 0
        glGetShaderiv(id, SGLOpenGL.GL_COMPILE_STATUS, &success)
        if (success == 0) {
            var info: [GLchar] = .init(unsafeUninitializedCapacity: 512) { buffer, initializedCount in
                initializedCount = 0
            }
            glGetShaderInfoLog(id, 512, nil, &info)
            let infoChars = info.map({ Character(Unicode.Scalar(UInt8($0))) })
            let reason = String(infoChars)
            throw(.init(type: type == GL_VERTEX_SHADER ? .vertexCompile : .fragmentCompile, reason: reason))
        }

        return id
    }
}

private extension SGLOpenGLWrapper {
    struct VertexBuffer: GLWrapperVertexBuffer {
        let vao: VertexArrayObjectIdentifier
        let vbo: VertexBufferIdentifier

        init() {
            var mutVAO: GLuint = 0
            glGenVertexArrays(1, &mutVAO)
            vao = mutVAO

            var mutVBO: GLuint = 0
            glGenBuffers(1, &mutVBO)
            vbo = mutVBO

            bind()
        }

        func activate() {
            bind()
        }

        func upload(data: UnsafeRawBufferPointer, 
                    describedAs descriptions: [GLWrapperAttributeDescriptor],
                    hint: GLWrapperUpdateHint = .staticDraw) throws (GLWrapperErrors.VertexBufferObjectError) {
            let stride = GLsizei(descriptions.reduce(0) { sum, item in sum + item.byteCount })
            guard stride > 0 else {
                throw .emptyDescriptorArray
            }

            guard data.count % Int(stride) == 0, let baseAddress = data.baseAddress else {
                throw .invalidBufferSizeForDescriptors(bufferSize: data.count, strideFromDescriptors: Int(stride))
            }

            bind()
            glBufferData(GL_ARRAY_BUFFER, data.count, UnsafeMutableRawPointer(mutating: baseAddress), hint.value)

            let strideUntilIndex: (Int) -> Int = {
                guard 1 <= $0 && $0 < descriptions.count else { return 0 }
                return descriptions[0 ..< $0].reduce(0, { $0 + $1.byteCount })
            }
            
            for pair in descriptions.enumerated() {
                glVertexAttribPointer(GLuint(pair.offset), 
                                      GLint(pair.element.componentsCount.rawValue), 
                                      GLint(pair.element.componentType.glEnumValue), 
                                      pair.element.shouldNormalize, 
                                      stride, 
                                      UnsafeRawPointer(bitPattern: strideUntilIndex(pair.offset)))
                glEnableVertexAttribArray(GLuint(pair.offset))
            }
        }

        private func bind() {
            glBindVertexArray(vao)
            glBindBuffer(GL_ARRAY_BUFFER, vbo)
        }
    }
}

private extension GLWrapperAttributeDescriptor.ComponentType {
    var byteCount: Int {
        switch self {
        case .float: MemoryLayout<GLfloat>.size
        case .int: MemoryLayout<Int>.size
        case .uint: MemoryLayout<UInt>.size
        }
    }

    var glEnumValue: GLenum {
        switch self {
        case .float: GL_FLOAT
        case .int: GL_INT
        case .uint: GL_UNSIGNED_INT
        }
    }
}

private extension GLWrapperAttributeDescriptor {
    var byteCount: Int {
        componentsCount.rawValue * componentType.byteCount
    }
}

private extension GLWrapperUpdateHint {
    var value: GLenum {
        switch self {
            case .staticDraw: GL_STATIC_DRAW
            case .dynamicDraw: GL_DYNAMIC_DRAW
            case .streamDraw: GL_STREAM_DRAW
        }
    }
}

private extension SGLOpenGLWrapper {
    class Program: GLWrapperProgram {
        private typealias Uniform<T> = (location: GLint, valuePtr: UnsafeMutablePointer<T>)

        private let id: ProgramIdentifier

        private var vec1fUniforms: [Uniform<GLfloat>] = []
        private var vec2fUniforms: [Uniform<Vec2f>] = []
        private var vec3fUniforms: [Uniform<Vec3f>] = []
        private var vec4fUniforms: [Uniform<Vec4f>] = []
        private var mat4fUniforms: [Uniform<Mat4f>] = []

        private var boundUniforms: [String: GLWrapperUniformValueType] = [:]

        func activate() {
            glUseProgram(id)
        }

        func bindVec1fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<GLfloat> {
            return bindUniform(name: named, type: .vec1f, storingInto: &vec1fUniforms)
        }

        func bindVec2fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec2f> {
            return bindUniform(name: named, type: .vec2f, storingInto: &vec2fUniforms)
        }

        func bindVec3fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec3f> {
        }

        func bindVec4fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec4f> {
        }

        func bindMat4fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Mat4f> {
        }

        private func bindUniform<T>(name: String, 
                                    type: GLWrapperUniformValueType, 
                                    storingInto array: inout Array<Uniform<T>>) 
                                    throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<T> {
            let location = try findUniformLocation(name: named)
            boundUniforms[named] = type

            let raw = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<T>.stride, alignment: MemoryLayout<T>.alignment)
            raw.initializeMemory(as: Int8.self, repeating: 0, count: MemoryLayout<T>.stride)
            let bound = raw.bindMemory(to: T.self, capacity: 1)

            array.append((location, raw))
        }


        private func findUniformLocation(name: String) throws(GLWrapperErrors.ProgramUniformError) -> GLint {
            if let type = boundUniforms[name] {
                throw .boundAlready(toType: type)
            }

            let value = name.withCString { ptr -> GLint in
                glGetUniformLocation(self.id, ptr)
            }

            guard value >= 0 else {
                throw .notFound(name: name)
            }

            return value
       }
    }
}

private extension GLWrapperDrawMode {
    var enumValue: GLenum {
        switch self {
            case .triangles: GL_TRIANGLES
            case .lines: GL_LINES
            case .points: GL_POINTS
        }
    }
}

private extension SGLOpenGLWrapper {
    struct Texture2D: GLWrapperTexture2D {
        let id: GLuint

        func activateOn(index: GLint) {
            glActiveTexture(GL_TEXTURE0 + index)
            glBindTexture(GL_TEXTURE_2D, id)
        }
    }
}

private extension GLWrapperColorFormat {
    var glEnumValue: GLint {
        switch self {
            case .rgb: GL_RGB
            case .rgba: GL_RGBA
        }
    }
}

private extension GLWrapperUniformValue {
    func activateOn(location: GLint) {
        switch self {
            case .vec1i(let value):
                glUniform1i(location, value)

            case .vec1f(let value):
                glUniform1f(location, value)

            case .vec2f(let vec2):
                glUniform2f(location, vec2.x, vec2.y)
            
            case .vec3f(let vec3):
                glUniform3f(location, vec3.x, vec3.y, vec3.z)

            case .vec4f(let vec4):
                glUniform4f(location, vec4.x, vec4.y, vec4.z, vec4.w)

            case .mat4f(let mat4Ptr, let isRowOrder):
                let rawPtr = UnsafeRawPointer(mat4Ptr);
                glUniformMatrix4fv(location, 1, isRowOrder, rawPtr.bindMemory(to: GLfloat.self, capacity: 16))
        }
    }
}