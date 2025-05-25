
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

    public enum VertexBufferObjectError: Swift.Error {
        case invalidBufferSizeForDescriptors(bufferSize: Int, strideFromDescriptors: Int)
        case emptyDescriptorArray
    }

    public enum ProgramUniformError: Swift.Error {
        case notFound(name: String)
        case boundAlready(toType: GLWrapperUniformValueType)
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

public typealias Vec4f = (x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
public typealias Vec3f = (x: GLfloat, y: GLfloat, z: GLfloat)
public typealias Vec2f = (x: GLfloat, y: GLfloat)

public typealias Mat4f = (Vec4f, Vec4f, Vec4f, Vec4f)

public enum GLWrapperUniformValueType: Sendable {
    case vec1i

    case vec1f
    case vec2f
    case vec3f    
    case vec4f
    case mat4f
}

public enum GLWrapperColorFormat {
    case rgb
    case rgba
}