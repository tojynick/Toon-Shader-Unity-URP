![alt text](https://github.com/tojynick/Toon-Shader-Unity-URP/blob/main/Readme%20Resources/Thumbnail.png)

# Features
* **Fully custom-written lightning** with support of *multiple lights, shadows, fog, lightmaps, you name it!*
* **Configurable smoothness of borders** between *specular*, *diffuse* and *ambient* parts of lightning for **stylized smooth** or **sharp toony** look.
* Separate *diffuse*, *specular* and *ambient* **tint**
* Specular highlight size
* Supports **albedo map** with configurable *scale* and *offset*

## Important Notes
### Compatability
The shader is tested only in **Unity 2021** and only with **URP**, so I cannot guarantee it will work properly in earlier versions of Unity or different render pipelines.
### Potential bugs in future versions of Unity (after 2021) 
The shader uses fully custom written HLSL code for light calculations. In future some URP keywords might change which might result in errors.
### Where is custom HLSL lightning file?
It's right there: **Assets/Shaders/Library/HLSL/ToonLightning.hlsl**

## Examples
[YouTube Video](https://www.youtube.com/watch?v=JDMmctA_5lc)
#### Dancing Robot
![alt text](https://github.com/tojynick/Toon-Shader-Unity-URP/blob/main/Readme%20Resources/Robot%20Dancing.gif)
#### Primitive Shapes
![alt text](https://github.com/tojynick/Toon-Shader-Unity-URP/blob/main/Readme%20Resources/Primitives.gif)
