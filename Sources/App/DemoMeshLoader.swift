import swiftSTBImage

struct Vec3 {
    let x: Float
    let y: Float
    let z: Float
}

func loadBasicTriangle<GLW: GLWrapper>(_ t: GLW.Type) throws -> Mesh<GLW> {
    let verticesv2: [(vertex: Vec3, color: Vec3)] = [
        (Vec3(x: 0.5, y: 0.5, z: 0.0), .init(x: 1.0, y: 0.0, z: 0.0)),
        (Vec3(x: -0.5, y: -0.5, z: 0.0), .init(x: 0.0, y: 1.0, z: 0.0)),
        (Vec3(x: 0.5, y: -0.5, z: 0.0), .init(x: 0.0, y: 0.0, z: 1.0)),
    ]
        let program = try GLW.createProgramWith(vertexShaderSource: basicVertexColorShader, 
                                                                        fragmentShaderSource: basicFragmentColorShader)
        let vertexBuffer = GLW.createVertexBuffer()
        try verticesv2.withUnsafeBufferPointer { ptr in
            let rawBufferPtr = UnsafeRawBufferPointer(ptr)
            try vertexBuffer.upload(data: rawBufferPtr, 
                                    describedAs: [
                                        .init(componentsCount: .vec3),
                                        .init(componentsCount: .vec3)
                                    ], 
                                    hint: .staticDraw)
        }

        return Mesh<GLW>(program: program, 
                         vertexBuffer: vertexBuffer, 
                         geometry: .init(drawMode: .triangles, vertexCount: verticesv2.count))
}

func loadTexturedMesh<GLW: GLWrapper>(_ t: GLW.Type) throws -> Mesh<GLW> {
    let w: GLfloat = 0.4
    let h: GLfloat = 0.8
    let vertexData: [(vertex: Vec3f, textureCoords: Vec2f)] = [
        ((-w, h, 0.0), (0.0, 1.0)), // top-left
        ((w, h, 0.0), (1.0, 1.0)), // top-right 
        ((-w, -h, 0.0), (0.0, 0.0)), // bottom-left

        ((w, h, 0.0), (1.0, 1.0)), // top-right
        ((w, -h, 0.0), (1.0, 0.0)), // bottom-right
        ((-w, -h, 0.0), (0.0, 0.0)) // bottom-left
    ]

    let program = try GLW.createProgramWith(vertexShaderSource: vertexTextureShader, 
                                                                    fragmentShaderSource: fragmentTextureShader)

    let urfTexture = try ResourceLoader<GLW>.loadUrf()
    let textures: [any GLWrapperTexture2D] = [urfTexture] 
    let texureUniformPtr = try program.bindVec1iUniform(named: "textureID")
    texureUniformPtr.pointee = 0

    let vertexBuffer = GLW.createVertexBuffer()
    try vertexData.withUnsafeBufferPointer { ptr in
        let rawBufferPtr = UnsafeRawBufferPointer(ptr)
        try vertexBuffer.upload(data: rawBufferPtr, 
                                describedAs: [
                                    .init(componentsCount: .vec3),
                                    .init(componentsCount: .vec2)
                                ], 
                                hint: .staticDraw)
    }

    return Mesh<GLW>(program: program, 
                     vertexBuffer: vertexBuffer, 
                     geometry: .init(drawMode: .triangles, vertexCount: vertexData.count),
                     textures: textures)
}