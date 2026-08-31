import bpy
import math
import os

def clean_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_cyber_card():
    clean_scene()
    
    # 1. Base Card Slab (Rounded/Beveled Box)
    # Dimensions: 3.4 x 2.1 x 0.08 (standard credit card ratio scaled)
    bpy.ops.mesh.primitive_cube_add(
        size=1.0, 
        location=(0, 0, 0),
        scale=(3.4, 2.1, 0.08)
    )
    card_base = bpy.context.active_object
    card_base.name = "CyberCardBase"
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_smooth()
    
    # Add Bevel Modifier
    bev = card_base.modifiers.new(name="Bevel", type='BEVEL')
    bev.width = 0.08
    bev.segments = 5
    
    # 2. Cyber Bezel Frame (Outer border ring)
    bpy.ops.mesh.primitive_cube_add(
        size=1.0,
        location=(0, 0, 0.02),
        scale=(3.3, 2.0, 0.08)
    )
    frame = bpy.context.active_object
    frame.name = "CyberFrame"
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    
    # 3. Holographic Chip / Vault Core (Left Side)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.45,
        depth=0.12,
        vertices=6, # Hexagonal Cyber Shield Core
        location=(-0.95, 0.35, 0.03)
    )
    hex_core = bpy.context.active_object
    hex_core.name = "VaultHexCore"
    bpy.ops.object.shade_smooth()
    
    # Inner glowing crystal on hex core
    bpy.ops.mesh.primitive_ico_sphere_add(
        radius=0.22,
        subdivisions=2,
        location=(-0.95, 0.35, 0.08)
    )
    crystal = bpy.context.active_object
    crystal.name = "VaultPowerCrystal"
    
    # 4. 3D Indian Rupee / Game Emblem on right side
    bpy.ops.object.text_add(location=(0.45, -0.25, 0.05))
    rupee_symbol = bpy.context.active_object
    rupee_symbol.name = "CardRupeeSymbol"
    rupee_symbol.data.body = "₹"
    rupee_symbol.data.extrude = 0.06
    rupee_symbol.data.bevel_depth = 0.015
    rupee_symbol.data.bevel_resolution = 3
    rupee_symbol.data.size = 0.95
    
    # 5. Cyber Circuit Stripes / Accent Lines
    bpy.ops.mesh.primitive_cube_add(
        size=1.0,
        location=(0.0, -0.65, 0.05),
        scale=(2.8, 0.04, 0.02)
    )
    stripe1 = bpy.context.active_object
    stripe1.name = "CyberStripe1"
    
    bpy.ops.mesh.primitive_cube_add(
        size=1.0,
        location=(0.3, 0.70, 0.05),
        scale=(2.0, 0.03, 0.02)
    )
    stripe2 = bpy.context.active_object
    stripe2.name = "CyberStripe2"

    # 6. Materials
    # Dark Titanium Cyber Body
    titanium_mat = bpy.data.materials.new(name="Titanium_Body")
    titanium_mat.use_nodes = True
    bsdf = titanium_mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.04, 0.07, 0.12, 1.0) # Deep Midnight Obsidian
        bsdf.inputs["Metallic"].default_value = 0.95
        bsdf.inputs["Roughness"].default_value = 0.22

    # Royal Blue / Sapphire Metallic Frame
    sapphire_mat = bpy.data.materials.new(name="Sapphire_Metal")
    sapphire_mat.use_nodes = True
    s_bsdf = sapphire_mat.node_tree.nodes.get("Principled BSDF")
    if s_bsdf:
        s_bsdf.inputs["Base Color"].default_value = (0.08, 0.35, 0.95, 1.0) # Electric Royal Blue
        s_bsdf.inputs["Metallic"].default_value = 0.92
        s_bsdf.inputs["Roughness"].default_value = 0.15

    # Glowing Gold Emblem
    gold_mat = bpy.data.materials.new(name="Gold_Emblem")
    gold_mat.use_nodes = True
    g_bsdf = gold_mat.node_tree.nodes.get("Principled BSDF")
    if g_bsdf:
        g_bsdf.inputs["Base Color"].default_value = (1.0, 0.80, 0.18, 1.0) # Golden Glow
        g_bsdf.inputs["Metallic"].default_value = 0.95
        g_bsdf.inputs["Roughness"].default_value = 0.10
        if "Emission Color" in g_bsdf.inputs:
            g_bsdf.inputs["Emission Color"].default_value = (1.0, 0.75, 0.1, 1.0)
            g_bsdf.inputs["Emission Strength"].default_value = 0.8

    # Glowing Neon Cyan Crystal
    neon_mat = bpy.data.materials.new(name="Neon_Cyan_Energy")
    neon_mat.use_nodes = True
    n_bsdf = neon_mat.node_tree.nodes.get("Principled BSDF")
    if n_bsdf:
        n_bsdf.inputs["Base Color"].default_value = (0.0, 0.9, 1.0, 1.0)
        n_bsdf.inputs["Metallic"].default_value = 0.1
        n_bsdf.inputs["Roughness"].default_value = 0.05
        if "Emission Color" in n_bsdf.inputs:
            n_bsdf.inputs["Emission Color"].default_value = (0.0, 0.95, 1.0, 1.0)
            n_bsdf.inputs["Emission Strength"].default_value = 3.0

    # Assign Materials
    card_base.data.materials.append(titanium_mat)
    frame.data.materials.append(sapphire_mat)
    hex_core.data.materials.append(sapphire_mat)
    crystal.data.materials.append(neon_mat)
    rupee_symbol.data.materials.append(gold_mat)
    stripe1.data.materials.append(neon_mat)
    stripe2.data.materials.append(gold_mat)

def export_gltf(output_path):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        use_selection=False,
        export_materials='EXPORT',
        export_apply=True
    )
    print(f"Exported 3D Cyber Vault Card GLB: {output_path}")

if __name__ == "__main__":
    out_file = r"e:\pc2\android  project\Task  project\ar-task-project\Worker app\assets\3d\vault_game_card_3d.glb"
    create_cyber_card()
    export_gltf(out_file)
