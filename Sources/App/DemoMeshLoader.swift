struct Vec3 {
    let x: Float
    let y: Float
    let z: Float
}

func loadBasicTriangle<GLW: GLWrapper>(_ t: GLW.Type) throws -> Mesh<GLW> {
    let vertices: [Float] = [
        // positions         // colors
         0.5, -0.5, 0.0,  0.0, 1.0, 0.0,  // bottom right
        -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,  // bottom left
         0.0,  0.5, 0.0,  0.0, 0.0, 1.0   // top 
    ];

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
