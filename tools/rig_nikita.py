"""Binds Nikita (unrigged, A-pose) to the Quaternius UE skeleton and exports a rigged glb.
Weights are copied from the Quaternius body (posed to match Nikita's A-pose), then the mesh is
un-posed to the rig's T-pose so the Universal Animation Library clips fit.
Run: blender -b -P tools/rig_nikita.py   (paths below are relative to the project root)
"""
import bpy, math, os
from mathutils import Matrix, Vector, kdtree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Inputs, extracted from the raw downloads: Quaternius "Universal Base Characters" (Godot - UE) and Nikita (n0mad).
BODY = ROOT + "/_raw/work/q/Universal Base Characters[Standard]/Base Characters/Godot - UE/Superhero_Male_FullBody.gltf"
NIKITA = ROOT + "/_raw/work/nikita_base_mesh/NikitaMesh_A_Pose.gltf"
OUT = ROOT + "/assets/models/characters/Nikita_Rigged.glb"
K = 4  # nearest body vertices blended per weight transfer
# part -> (colour; the body is tinted per kind in Godot, so it stays white)
COLOURS = {
    "Nikita": (1, 1, 1), "Helmet": (0.22, 0.26, 0.2), "Vest": (0.12, 0.14, 0.2), "Chest_rig": (0.2, 0.2, 0.16),
    "Backpack": (0.18, 0.2, 0.26), "Holster": (0.1, 0.1, 0.1), "Shemag": (0.55, 0.5, 0.38),
    "Knee_pads": (0.1, 0.1, 0.1), "Goggles": (0.05, 0.05, 0.06),
}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=BODY)
bpy.ops.import_scene.gltf(filepath=NIKITA)
O = bpy.data.objects
arm = next(o for o in O if o.type == "ARMATURE")
body = O["SuperHero_Male"]
for n in ("Icosphere", "ShadowCatcher", "Flag", "Eyes", "Eyebrows"):
    if n in O:
        O.remove(O[n], do_unlink=True)
parts = [O[n] for n in COLOURS]

# 1. Pose the arms into Nikita's A-pose.
tip = max((v.co for v in O["Nikita"].data.vertices), key=lambda c: c.x)
for side, sign in (("l", 1), ("r", -1)):
    pb = arm.pose.bones["upperarm_" + side]
    head = pb.bone.head_local
    theta = math.atan2(head.z - tip.z, abs(tip.x) - abs(head.x))
    print("A-pose drop", math.degrees(theta))
    R = Matrix.Rotation(sign * theta, 4, "Y")
    pb.matrix = Matrix.Translation(head) @ R @ Matrix.Translation(-head) @ pb.bone.matrix_local
bpy.context.view_layer.update()

# 2. Per-bone skinning matrices of that pose (armature space).
skin = {b.name: arm.pose.bones[b.name].matrix @ b.matrix_local.inverted() for b in arm.data.bones}
names = {vg.index: vg.name for vg in body.vertex_groups}

# 3. KD-tree of the posed Quaternius body, to copy weights from.
ev = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
posed = ev.to_mesh()
tree = kdtree.KDTree(len(posed.vertices))
for i, v in enumerate(posed.vertices):
    tree.insert(v.co, i)
tree.balance()

# 4. Weights for every part, then un-pose the vertices: v_T = (sum w_i * skin_i)^-1 * v_A.
for o in parts:
    for n in set(names.values()):
        if n not in o.vertex_groups:
            o.vertex_groups.new(name=n)
    for v in o.data.vertices:
        w = {}
        near = tree.find_n(v.co, K)
        total = sum(1 / (d + 1e-4) for _, _, d in near)
        for _, i, d in near:
            for g in body.data.vertices[i].groups:
                w[names[g.group]] = w.get(names[g.group], 0) + g.weight / (d + 1e-4) / total
        blend = Matrix(((0,) * 4,) * 4)
        for n, wt in w.items():
            blend = blend + skin[n] * wt
            o.vertex_groups[n].add([v.index], wt, "REPLACE")
        v.co = (blend.inverted() @ v.co.to_4d()).to_3d()
for pb in arm.pose.bones:
    pb.matrix_basis = Matrix()
bpy.context.view_layer.update()

# 5. Parent to the armature, name materials, drop the donor body, export.
for o in parts:
    o.parent = arm
    o.modifiers.new("Armature", "ARMATURE").object = arm
    m = bpy.data.materials.new(o.name)
    m.diffuse_color = (*COLOURS[o.name], 1)
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*COLOURS[o.name], 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    o.data.materials.clear()
    o.data.materials.append(m)
O.remove(body, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
for o in parts:
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_animations=False, export_yup=True)
print("exported", OUT)
