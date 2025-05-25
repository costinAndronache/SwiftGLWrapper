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

        glTexImage2D(GL_TEXTURE_2D, 
                     mipMapStages, 
                     format.glEnumValue, 
                     width, 
                     height, 
                     0, 
                     format.glEnumValue, 
                     GL_UNSIGNED_BYTE, 
                     data);

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

        private var vec1iUniforms: [Uniform<GLint>] = []
        private var vec1fUniforms: [Uniform<GLfloat>] = []
        private var vec2fUniforms: [Uniform<Vec2f>] = []
        private var vec3fUniforms: [Uniform<Vec3f>] = []
        private var vec4fUniforms: [Uniform<Vec4f>] = []
        private var mat4fUniforms: [Uniform<Mat4f>] = []

        private var boundUniforms: [String: GLWrapperUniformValueType] = [:]
        private var rowOrderMat4fUniformLocations: Set<GLint> = []

        init(id: ProgramIdentifier) {
            self.id = id
        }

        func activate() {
            glUseProgram(id)

            for uniform in vec1iUniforms {
                glUniform1i(uniform.location, uniform.valuePtr.pointee)
            }

            for uniform in vec1fUniforms {
                glUniform1f(uniform.location, uniform.valuePtr.pointee)  
            }

            for uniform in vec2fUniforms {
                let vec2 = uniform.valuePtr.pointee
                glUniform2f(uniform.location, vec2.x, vec2.y)
            }
            
            for uniform in vec3fUniforms {
                let vec3 = uniform.valuePtr.pointee
                glUniform3f(uniform.location, vec3.x, vec3.y, vec3.z)
            }

            for uniform in vec4fUniforms {
                let vec4 = uniform.valuePtr.pointee
                glUniform4f(uniform.location, vec4.x, vec4.y, vec4.z, vec4.w)
            }

            for uniform in mat4fUniforms {
                let isRowOrder = rowOrderMat4fUniformLocations.contains(uniform.location)
                
                let rawPtr = UnsafeRawPointer(uniform.valuePtr);
                glUniformMatrix4fv(uniform.location, 1, isRowOrder, rawPtr.bindMemory(to: GLfloat.self, capacity: 16))
            }
        }

        func bindVec1iUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<GLint> {
            return try bindUniform(name: named, type: .vec1i, storingInto: &vec1iUniforms).valuePtr
        }

        func bindVec1fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<GLfloat> {
            return try bindUniform(name: named, type: .vec1f, storingInto: &vec1fUniforms).valuePtr
        }

        func bindVec2fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec2f> {
            return try bindUniform(name: named, type: .vec2f, storingInto: &vec2fUniforms).valuePtr
        }

        func bindVec3fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec3f> {
            return try bindUniform(name: named, type: .vec3f, storingInto: &vec3fUniforms).valuePtr
        }

        func bindVec4fUniform(named: String) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Vec4f> {
            return try bindUniform(name: named, type: .vec4f, storingInto: &vec4fUniforms).valuePtr
        }

        func bindMat4fUniform(named: String, inRowOrder: Bool) throws (GLWrapperErrors.ProgramUniformError) -> UnsafeMutablePointer<Mat4f> {
            let result = try bindUniform(name: named, type: .mat4f, storingInto: &mat4fUniforms)
            rowOrderMat4fUniformLocations.insert(result.location)
            return result.valuePtr
        }

        private func bindUniform<T>(name: String, 
                                    type: GLWrapperUniformValueType, 
                                    storingInto array: inout Array<Uniform<T>>) 
                                    throws (GLWrapperErrors.ProgramUniformError) -> Uniform<T> {
            let location = try findUniformLocation(name: name)
            boundUniforms[name] = type

            let raw = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<T>.stride, alignment: MemoryLayout<T>.alignment)
            raw.initializeMemory(as: Int8.self, repeating: 0, count: MemoryLayout<T>.stride)
            let bound = raw.bindMemory(to: T.self, capacity: 1)

            let result = (location, bound)
            array.append(result)
            return result
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