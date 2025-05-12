import SGLOpenGL


public typealias GLenum = Int32
public typealias GLboolean = Bool
public typealias GLbitfield = UInt32
public typealias GLbyte = Int8
public typealias GLshort = Int16
public typealias GLint = Int32
public typealias GLclampx = Int32
public typealias GLubyte = UInt8
public typealias GLushort = UInt16
public typealias GLuint = UInt32
public typealias GLsizei = Int32
public typealias GLfloat = Float
public typealias GLclampf = Float
public typealias GLdouble = Double
public typealias GLclampd = Double
public typealias GLeglImageOES = UnsafeMutableRawPointer
public typealias GLchar = Int8
public typealias GLcharARB = Int8
public typealias GLhandleARB = UnsafeMutableRawPointer
public typealias GLhalfARB = UInt16
public typealias GLhalf = UInt16
public typealias GLfixed = Int32
public typealias GLintptr = Int
public typealias GLsizeiptr = Int
public typealias GLint64 = Int64
public typealias GLuint64 = UInt64
public typealias GLintptrARB = Int
public typealias GLsizeiptrARB = Int
public typealias GLint64EXT = Int64
public typealias GLuint64EXT = UInt64
public typealias GLsync = OpaquePointer
public typealias GLhalfNV = UInt16
public typealias GLvdpauSurfaceNV = Int

public enum GLWrapperErrors {
    public struct ProgramError: Swift.Error {
        public enum StepType: Sendable { 
            case vertexCompile
            case fragmentCompile
            case programLink
        }
        public let type: StepType
        public let reason: String
    }

    public enum VertexBufferObjectError: Swift.Error, @unchecked Sendable {
        case invalidBufferSizeForDescriptors(bufferSize: Int, strideFromDescriptors: Int)
        case emptyDescriptorArray
    }
}

public struct GLWrapperAttributeDescriptor {
    public enum ComponentType {
        case float
        case int
        case uint
    }

    public enum ComponentCount: Int {
        case vec1 = 1
        case vec2
        case vec3
        case vec4
    }

    let componentsCount: ComponentCount
    let componentType: ComponentType
    let shouldNormalize: Bool

    public init(componentsCount: ComponentCount, componentType: ComponentType = .float, shouldNormalize: Bool = false) {
        self.componentsCount = componentsCount
        self.componentType = componentType
        self.shouldNormalize = false
    }
}

public enum GLWrapperUpdateHint {
    case staticDraw
    case dynamicDraw
    case streamDraw
}

public enum GLWrapperDrawMode {
    case triangles
    case lines
    case points
}

public struct GLWrapperGeometryDescription {
    public let drawMode: GLWrapperDrawMode
    public let vertexCount: Int
}

public protocol GLWrapperVertexBuffer {
    func upload(data: UnsafeRawBufferPointer, 
                describedAs descriptions: [GLWrapperAttributeDescriptor],
                hint: GLWrapperUpdateHint) throws (GLWrapperErrors.VertexBufferObjectError) -> Void
    func activate()
}

public protocol GLWrapperProgram {
    func activate()
}

public protocol GLWrapper {
    static func glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei)
    static func glClearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
    static func glClear(_ mask: GLbitfield)
    static func createProgramWith(vertexShaderSource: String, 
                                  fragmentShaderSource: String) 
                                  throws (GLWrapperErrors.ProgramError)-> (any GLWrapperProgram)
    
    static func createVertexBuffer() -> (any GLWrapperVertexBuffer)
    static func glDrawArrays(_ geometry: GLWrapperGeometryDescription)
}


public let GL: any GLWrapper.Type = SGLOpenGLWrapper.self



///////////////////////////////////////////////////////////////////////////////////////////////////

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

    public static func createVertexBuffer() -> (any GLWrapperVertexBuffer) {
        VertexBuffer()
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
    struct Program: GLWrapperProgram {
        let id: ProgramIdentifier

        func activate() {
            glUseProgram(id)
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