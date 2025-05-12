
func loadBasicTriangle<GLW: GLWrapper>(_ t: GLW.Type) throws -> Mesh<GLW> {
    let vertices: [Float] = [
        // positions         // colors
         0.5, -0.5, 0.0,  0.0, 1.0, 0.0,  // bottom right
        -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,  // bottom left
         0.0,  0.5, 0.0,  0.0, 0.0, 1.0   // top 
    ];
        let program = try GLW.createProgramWith(vertexShaderSource: basicVertexColorShader, 
                                                                        fragmentShaderSource: basicFragmentColorShader)
        let vertexBuffer = GLW.createVertexBuffer()
        try vertices.withUnsafeBufferPointer { ptr in
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
                    geometry: .init(drawMode: .triangles, vertexCount: 3))
}