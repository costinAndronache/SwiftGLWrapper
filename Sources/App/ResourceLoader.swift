import swiftSTBImage

enum ResourceLoaderError: Swift.Error {
    case textureLoadFailed(reason: String)
}

struct ResourceLoader<GLW: GLWrapper> {
    static func loadUrf() throws (ResourceLoaderError) -> (any GLWrapperTexture2D) {
        let path = "E:\\urf.png"
        return try loadFrom(path: path)
    }

    private static func loadFrom(path: String) throws(ResourceLoaderError) -> (any GLWrapperTexture2D) {
        stbi_set_flip_vertically_on_load(Int32(truncating: true))
        var width: Int32 = 0
        var height: Int32 = 0
        var channels: Int32 = 0

        guard let ptr = stbi_load(path, &width, &height, &channels, 0) else {
            if let reasonCStr = stbi_failure_reason() {
                throw .textureLoadFailed(reason: .init(cString: reasonCStr))
            } else {
                throw .textureLoadFailed(reason: "unknown")
            }
        }

        guard channels == 3 || channels == 4 else {
            throw .textureLoadFailed(reason: "Unsupported number of channels: \(channels)")
        }

        return GLW.createTexture2D(width: width, 
                                   height: height, 
                                   mipMapStages: 0, 
                                   format: channels == 3 ? .rgb : .rgba, 
                                   data: UnsafeRawPointer(ptr))
    }
}