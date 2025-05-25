let basicVertexColorShader: String = """
#version 330 core
precision highp float;

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

out vec4 vertexColor; 

void main()
{
    gl_Position = vec4(aPos, 1.0); // see how we directly give a vec3 to vec4's constructor
    vertexColor = vec4(aColor, 1.0);
}
"""

let basicFragmentColorShader: String = """
#version 330 core
out vec4 FragColor;
  
in vec4 vertexColor; // the input variable from the vertex shader (same name and same type)  

void main()
{
    FragColor = vertexColor;
} 
"""

////// With Textures 

let vertexTextureShader: String = """
#version 330 core
precision highp float;

layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 inputTexCoords;

out vec2 texCoords;

void main()
{
    gl_Position = vec4(pos, 1.0); // see how we directly give a vec3 to vec4's constructor
    texCoords = inputTexCoords;
}
"""

let fragmentTextureShader: String = """
#version 330 core

in vec2 texCoords; 

uniform sampler2D textureID;

out vec4 FragColor;

void main()
{
    FragColor = texture(textureID, texCoords);
} 
"""