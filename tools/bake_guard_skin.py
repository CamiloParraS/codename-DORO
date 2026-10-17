# Bakes a Characters PSX texture onto Nikita's UVs (the guards' skins). Needs the pack extracted to _raw/work/bake/:
# blender -b --python tools/bake_guard_skin.py -- Character_21_Police <out.png>
import bpy, sys, mathutils
name, out = sys.argv[sys.argv.index("--") + 1:][:2]
D = "D:/Projects/codename-doro/"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=D + "assets/models/characters/Nikita_Rigged.glb")
nik = bpy.data.objects["Nikita"]
keep = {nik}
bpy.ops.import_scene.fbx(filepath=D + "_raw/work/bake/%s.fbx" % name)
psx = bpy.data.objects[name]
for o in list(bpy.data.objects):
    if o.type == 'MESH' and o not in (nik, psx):
        bpy.data.objects.remove(o)
def bbox(o):
    ev = o.evaluated_get(bpy.context.evaluated_depsgraph_get())
    pts = [o.matrix_world @ mathutils.Vector(c) for c in ev.bound_box]
    return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]
nb0, nb1 = bbox(nik); pb0, pb1 = bbox(psx)
print("nik", nb0, nb1, "psx", pb0, pb1)
# match height (the axis with the biggest extent that isn't width: use z), feet and x/y centre
s = (nb1[2] - nb0[2]) / (pb1[2] - pb0[2])
root = psx.parent or psx
root.scale = root.scale * s; bpy.context.view_layer.update()
pb0, pb1 = bbox(psx)
root.location += mathutils.Vector(((nb0[0] + nb1[0]) / 2 - (pb0[0] + pb1[0]) / 2, (nb0[1] + nb1[1]) / 2 - (pb0[1] + pb1[1]) / 2, nb0[2] - pb0[2]))
bpy.context.view_layer.update()
print("aligned", bbox(psx))
# PSX material: its png, nearest
img = bpy.data.images.load(D + "_raw/work/bake/%s.png" % name)
m = bpy.data.materials.new("psx"); m.use_nodes = True
t = m.node_tree.nodes.new("ShaderNodeTexImage"); t.image = img; t.interpolation = 'Closest'
bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
m.node_tree.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
psx.data.materials.clear(); psx.data.materials.append(m)
# target image on Nikita
res = 512
tgt = bpy.data.images.new("bake", res, res)
nm = nik.data.materials[0]; nm.use_nodes = True
tn = nm.node_tree.nodes.new("ShaderNodeTexImage"); tn.image = tgt; nm.node_tree.nodes.active = tn
bpy.context.scene.render.engine = 'CYCLES'; bpy.context.scene.cycles.samples = 1; bpy.context.scene.cycles.device = 'CPU'
for o in bpy.context.selected_objects: o.select_set(False)
psx.select_set(True); nik.select_set(True); bpy.context.view_layer.objects.active = nik
bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, use_selected_to_active=True, cage_extrusion=0.4, max_ray_distance=0.8, margin=12, margin_type='EXTEND')
tgt.filepath_raw = out; tgt.file_format = 'PNG'; tgt.save()
print("saved", out)
