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

public protocol GLWrapper {
    static func glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei)
    static func glClearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
    static func glClear(_ mask: GLbitfield)
}


public let GL: GLWrapper.Type = SGLOpenGLWrapper.self

private enum SGLOpenGLWrapper: GLWrapper {
    static func glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) {
        SGLOpenGL.glViewport(x: x, y: y, width: width, height: height)
    }

    static func glClearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {
        SGLOpenGL.glClearColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func glClear(_ mask: GLbitfield) {
        SGLOpenGL.glClear(mask)
    }
}