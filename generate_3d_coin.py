import bpy
import math
import os

def clean_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_game_coin():
    clean_scene()
    
    # 1. Create Coin Base (Cylinder)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=1.0, 
        depth=0.18, 
        vertices=64, 
        location=(0, 0, 0)
    )
    coin = bpy.context.active_object
    coin.name = "GameCoin"
    
    # Smooth shading
    bpy.ops.object.shade_smooth()
    
    # Add Bevel Modifier for realistic metallic edges
    bevel = coin.modifiers.new(name="Bevel", type='BEVEL')
    bevel.width = 0.03
    bevel.segments = 4
    
    # 2. Add Outer Raised Rim (Torus/Cylinder)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.96,
        depth=0.20,
        vertices=64,
        location=(0, 0, 0)
    )
    rim = bpy.context.active_object
    rim.name = "CoinRim"
    bpy.ops.object.shade_smooth()
    
    # Boolean difference or inner inset ring
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.88,
        depth=0.22,
        vertices=64,
        location=(0, 0, 0)
    )
    inner_cut = bpy.context.active_object
    
    # 3. Create 3D Rupee Symbol Text
    bpy.ops.object.text_add(location=(-0.32, -0.42, 0.10))
    text_obj = bpy.context.active_object
    text_obj.name = "RupeeSymbol"
    text_obj.data.body = "₹"
    text_obj.data.extrude = 0.05
    text_obj.data.bevel_depth = 0.015
    text_obj.data.bevel_resolution = 3
    text_obj.data.size = 0.95
    
    # Also add rupee to back side
    bpy.ops.object.text_add(location=(0.32, -0.42, -0.10), rotation=(0, math.pi, 0))
    text_back = bpy.context.active_object
    text_back.name = "RupeeSymbolBack"
    text_back.data.body = "₹"
    text_back.data.extrude = 0.05
    text_back.data.bevel_depth = 0.015
    text_back.data.bevel_resolution = 3
    text_back.data.size = 0.95
    
    # 4. Add Decorative Stars around the rim
    star_count = 8
    for i in range(star_count):
        angle = i * (2 * math.pi / star_count)
        r = 0.78
        x = r * math.cos(angle)
        y = r * math.sin(angle)
        
        # Small sphere/gem on front rim
        bpy.ops.mesh.primitive_ico_sphere_add(
            radius=0.035, 
            subdivisions=2, 
            location=(x, y, 0.10)
        )
        gem = bpy.context.active_object
        gem.name = f"Gem_Front_{i}"
        
        # Small gem on back rim
        bpy.ops.mesh.primitive_ico_sphere_add(
            radius=0.035, 
            subdivisions=2, 
            location=(x, y, -0.10)
        )
        gem_b = bpy.context.active_object
        gem_b.name = f"Gem_Back_{i}"

    # 5. Create Materials
    # Gold Metallic Material
    gold_mat = bpy.data.materials.new(name="Gold_PBR")
    gold_mat.use_nodes = True
    nodes = gold_mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        # Base color: Rich Radiant Gold
        bsdf.inputs["Base Color"].default_value = (1.0, 0.76, 0.15, 1.0)
        bsdf.inputs["Metallic"].default_value = 0.98
        bsdf.inputs["Roughness"].default_value = 0.18
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = 0.8
        elif "Specular" in bsdf.inputs:
            bsdf.inputs["Specular"].default_value = 0.8

    # Glowing Gem Material
    gem_mat = bpy.data.materials.new(name="Neon_Cyan_Gem")
    gem_mat.use_nodes = True
    g_nodes = gem_mat.node_tree.nodes
    g_bsdf = g_nodes.get("Principled BSDF")
    if g_bsdf:
        g_bsdf.inputs["Base Color"].default_value = (0.0, 0.85, 1.0, 1.0)
        g_bsdf.inputs["Metallic"].default_value = 0.3
        g_bsdf.inputs["Roughness"].default_value = 0.05
        if "Emission Color" in g_bsdf.inputs:
            g_bsdf.inputs["Emission Color"].default_value = (0.0, 0.8, 1.0, 1.0)
            g_bsdf.inputs["Emission Strength"].default_value = 2.5

    # Assign materials
    for obj in bpy.data.objects:
        if "Gem" in obj.name:
            obj.data.materials.append(gem_mat)
        elif obj.type in ['MESH', 'FONT']:
            obj.data.materials.append(gold_mat)

    # 6. Lighting & Studio Camera Setup
    # Key Light (Warm Gold)
    bpy.ops.object.light_add(type='AREA', location=(2.5, -2.5, 3.0), rotation=(math.radians(45), 0, math.radians(45)))
    key_light = bpy.context.active_object
    key_light.data.energy = 450
    key_light.data.color = (1.0, 0.92, 0.75)
    key_light.data.size = 2.0

    # Fill Light (Cool Cyan Cyber)
    bpy.ops.object.light_add(type='AREA', location=(-2.5, 2.5, 2.0), rotation=(math.radians(45), 0, math.radians(-135)))
    fill_light = bpy.context.active_object
    fill_light.data.energy = 250
    fill_light.data.color = (0.3, 0.7, 1.0)
    fill_light.data.size = 2.0

    # Rim / Backlight
    bpy.ops.object.light_add(type='POINT', location=(0, 0, -2.5))
    rim_light = bpy.context.active_object
    rim_light.data.energy = 150
    rim_light.data.color = (1.0, 0.6, 0.1)

    # Camera
    bpy.ops.object.camera_add(location=(0, -3.2, 0.8), rotation=(math.radians(78), 0, 0))
    cam = bpy.context.active_object
    bpy.context.scene.camera = cam

    # Render settings
    scene = bpy.context.scene
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100

    return coin

def export_assets(output_dir):
    os.makedirs(output_dir, exist_ok=True)
    
    # 1. Export 3D GLB Model
    glb_path = os.path.join(output_dir, "balance_coin_3d.glb")
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=False,
        export_materials='EXPORT',
        export_apply=True
    )
    print(f"Exported GLB: {glb_path}")

    # 2. Render 3D Isometric View
    render_iso_path = os.path.join(output_dir, "3d_coin_isometric.png")
    bpy.context.scene.render.filepath = render_iso_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered 3D Isometric Image: {render_iso_path}")

    # 3. Render 3D Front Angle
    cam = bpy.context.scene.camera
    cam.location = (0, -3.0, 0)
    cam.rotation_euler = (math.radians(90), 0, 0)
    render_front_path = os.path.join(output_dir, "3d_coin_front.png")
    bpy.context.scene.render.filepath = render_front_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered 3D Front Image: {render_front_path}")

if __name__ == "__main__":
    out_dir = r"e:\pc2\android  project\Task  project\ar-task-project\Worker app\assets\3d"
    create_game_coin()
    export_assets(out_dir)
    print("Blender 3D Asset Creation Completed Successfully!")
