# DirectX HLSL PBR shader for Max and Maya
A WIP Implementation of a Physically Plausible (PBR/PBS) HLSL Shader that works in both Autodesk 3Ds Max and Autodesk Maya viewports.

This is a simplified and modified version of Maya-PBR-BRDF-VP2 by hogjonny
https://github.com/hogjonny/Maya-PBR-BRDF-VP2

simplePBR.fx is the main file. simplePBRMaya and simplePBRMax are used to make sure, that value used by shader to recognise software is set.

![alt tag](https://github.com/p4vv37/DirectX-HLSL-PBR-shader-for-Max-and-Maya/blob/master/images/first_preview.PNG)

# How to use
As in Maya-PBR-BRDF-VP2 by hogjonny Diffuse IBL and Specular IBL need to be .dds maps. They can be generated from hdr files with https://github.com/derkreature/IBLBaker

Maya:
Compile the .fx file to fxo with fxc.exe or use compile_for_maya.bat
In Maya:
- make sure, that dx11Shader.mll plugin is loded. 
- create a dx11Shader material
- Load generated .fxo file as a Shader File
- load textures: Diffuse, Metalness, Roughness
- Load IBL textures: Diffuse IBL and Specular IBL

Max:
- Create DirectX Shader
- Select mode "HLSL File"
- Load simplePBRMax.fx file
- load textures: Diffuse, Metalness, Roughness
- Load IBL textures: Diffuse IBL and Specular IBL
