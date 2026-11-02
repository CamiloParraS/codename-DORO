# Builds the identity-pass props (garage, lab, vault, Core, harbour) and exports each to
# assets/models/props/<name>.glb. Headless (Blender's path is in docs/GUIDE.md):
#   blender -b --factory-startup -P tools/model_identity_props.py -- [name ...]
# A full run (no names) also saves every model to _raw/blender/identity_props.blend; a named run leaves it alone.
# Front faces Blender +Y (glTF -Z): a DRESS entry's facing is the bearing the front looks at.
# Base on z = 0. Textures are the project's own (assets/textures), box-projected 1 m per repeat.
import bpy, sys, os, math

ROOT = "D:/Projects/codename-doro"
TEX = ROOT + "/assets/textures/"
OUT = ROOT + "/assets/models/props/"
ONLY = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

_mats = {}


def mat(name, col, tex=None, emit=None, alpha=None, rough=0.9):
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = 0.0
    if tex:
        img = nt.nodes.new("ShaderNodeTexImage")
        img.image = bpy.data.images.load(TEX + tex, check_existing=True)
        img.interpolation = "Closest"
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        nt.links.new(img.outputs["Color"], mix.inputs["A"])
        mix.inputs["B"].default_value = (*col, 1)
        nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = (*col, 1)
    if emit:
        bsdf.inputs["Emission Color"].default_value = (*emit[0], 1)
        bsdf.inputs["Emission Strength"].default_value = emit[1]
    if alpha is not None:
        bsdf.inputs["Alpha"].default_value = alpha
        m.surface_render_method = "BLENDED"
    _mats[name] = m
    return m


# a few shared materials
def steel(): return mat("steel", (0.62, 0.64, 0.66), "metal_05_128.png")
def dark(): return mat("dark", (0.16, 0.17, 0.18), "metal_05_128.png")
def black(): return mat("black", (0.05, 0.05, 0.05))
def white(): return mat("white", (0.88, 0.9, 0.9), "panels_128.png")
def yellow(): return mat("yellow", (1.0, 0.72, 0.08), "metal_05_128.png")
def red(): return mat("red", (0.75, 0.08, 0.06), "metal_05_128.png")
def rubber(): return mat("rubber", (0.12, 0.12, 0.12), "asphalt_128.png")
def wood(): return mat("wood", (0.75, 0.6, 0.45), "wood_07_128.png")
def hazard(): return mat("hazard", (1, 1, 1), "hazard_128.png")
def glass(): return mat("glass", (0.6, 0.8, 0.85), alpha=0.3, rough=0.1)
def glow(c, s=3.0): return mat("glow_%.2f_%.2f_%.2f" % c, c, emit=(c, s))


_parts = []


def box(size, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=[math.radians(a) for a in rot])
    o = bpy.context.active_object
    o.scale = size
    o.data.materials.append(m)
    _parts.append(o)
    return o


def cyl(r, h, loc, m, rot=(0, 0, 0), v=12, r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=h, location=loc, rotation=[math.radians(a) for a in rot])
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r, radius2=r2, depth=h, location=loc, rotation=[math.radians(a) for a in rot])
    o = bpy.context.active_object
    o.data.materials.append(m)
    _parts.append(o)
    return o


def torus(R, r, loc, m, rot=(0, 0, 0), maj=16, mn=6):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=maj, minor_segments=mn,
        location=loc, rotation=[math.radians(a) for a in rot])
    o = bpy.context.active_object
    o.data.materials.append(m)
    _parts.append(o)
    return o


def finish(name):
    """Join the parts, box-project UVs, export."""
    global _parts
    bpy.ops.object.select_all(action="DESELECT")
    for p in _parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = _parts[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.cube_project(cube_size=1.0)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.export_scene.gltf(filepath=OUT + name + ".glb", export_format="GLB", use_selection=True,
        export_apply=True, export_yup=True)
    print("EXPORTED", name, tuple(round(d, 2) for d in o.dimensions))
    col = bpy.data.collections.get("done") or bpy.data.collections.new("done")
    if col.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(col)
    for c in o.users_collection:
        c.objects.unlink(o)
    col.objects.link(o)
    o.hide_set(True)
    _parts = []


# --- garage --------------------------------------------------------------------------------------

def lift_post():
    # origin at the post; the arms reach forward (+Y) under the vehicle
    box((0.7, 0.7, 0.04), (0, 0, 0.02), dark())
    box((0.32, 0.32, 3.6), (0, 0, 1.8), yellow())
    box((0.08, 0.08, 3.4), (0, 0.2, 1.75), dark())  # the slide rail
    box((0.42, 0.42, 0.55), (0, 0.05, 0.6), dark())  # carriage
    for a in (-28, 28):
        rad = math.radians(a)
        l = 1.5
        cx, cy = math.sin(rad) * l / 2, 0.25 + math.cos(rad) * l / 2
        box((0.12, l, 0.1), (cx, cy, 0.42), yellow(), (0, 0, -a))
        cyl(0.11, 0.08, (math.sin(rad) * l, 0.25 + math.cos(rad) * l, 0.5), rubber())
    box((0.5, 0.5, 0.25), (0, 0, 3.7), dark())  # the top cap
    box((0.22, 0.12, 0.22), (0.25, 0, 1.2), red())  # the control box
    box((0.04, 0.02, 0.06), (0.25, 0.07, 1.25), glow((0.2, 1, 0.3), 2))


def tool_board():
    box((1.8, 0.04, 1.0), (0, 0.02, 0.5), mat("pegboard", (0.62, 0.47, 0.32), "wood_07_128.png"))
    box((1.9, 0.06, 0.06), (0, 0.03, 1.02), dark())
    box((1.9, 0.06, 0.06), (0, 0.03, -0.02), dark())
    st = steel()
    # wrenches, small to large
    for i, l in enumerate((0.18, 0.22, 0.26, 0.3, 0.34)):
        x = -0.75 + i * 0.1
        box((0.025, 0.02, l), (x, 0.05, 0.75 - l / 2), st)
        box((0.06, 0.02, 0.04), (x, 0.05, 0.77), st)
    # hammer, saw, screwdrivers
    box((0.04, 0.03, 0.34), (-0.15, 0.05, 0.55), wood())
    box((0.16, 0.04, 0.05), (-0.15, 0.05, 0.73), dark())
    box((0.45, 0.01, 0.14), (0.2, 0.05, 0.72), st)
    box((0.12, 0.03, 0.12), (-0.04, 0.05, 0.72), red())
    for i in range(5):
        x = 0.55 + i * 0.07
        cyl(0.012, 0.16, (x, 0.05, 0.38), st)
        cyl(0.022, 0.09, (x, 0.05, 0.5), [red(), yellow(), red(), black(), yellow()][i])
    # outline paint behind the tools
    box((0.5, 0.005, 0.35), (-0.55, 0.042, 0.6), mat("outline", (0.25, 0.25, 0.25)))


def workbench():
    box((2.0, 0.75, 0.06), (0, 0, 0.9), steel())
    for x in (-0.95, 0.95):
        for y in (-0.33, 0.33):
            box((0.06, 0.06, 0.87), (x, y, 0.435), dark())
    box((1.9, 0.6, 0.04), (0, 0, 0.15), dark())  # lower shelf
    box((0.62, 0.62, 0.82), (-0.62, 0, 0.42), red())  # tool chest
    for z in (0.2, 0.42, 0.62, 0.78):
        box((0.56, 0.02, 0.012), (-0.62, 0.315, z), steel())
    box((0.22, 0.2, 0.14), (0.75, 0.3, 1.0), dark())  # vise
    box((0.04, 0.24, 0.04), (0.75, 0.45, 0.98), steel())
    box((0.45, 0.22, 0.2), (0.15, -0.15, 1.03), red())  # tool box
    box((0.3, 0.04, 0.03), (0.15, -0.15, 1.16), dark())
    box((0.37, 0.23, 0.26), (-0.5, -0.1, 1.06), mat("battery", (0.1, 0.1, 0.12), "metal_05_128.png"))  # a battery on charge
    box((0.2, 0.15, 0.1), (-0.2, 0.15, 0.98), yellow())  # charger


def tyre_stack():
    t = rubber()
    for i in range(4):
        z = 0.11 + i * 0.22
        torus(0.25, 0.11, (0, 0, z), t, maj=14, mn=6)
        cyl(0.16, 0.2, (0, 0, z), mat("hub", (0.3, 0.3, 0.32), "metal_05_128.png"), v=10)


def engine_hoist():
    y = yellow()
    for a in (-14, 14):
        r = math.radians(a)
        box((0.08, 1.5, 0.08), (math.sin(r) * 0.75, 0.75, 0.12), y, (0, 0, -a))
        cyl(0.06, 0.06, (math.sin(r) * 1.5, 1.5, 0.04), rubber(), (90, 0, 0))
    box((0.5, 0.1, 0.1), (0, 0, 0.12), y)
    box((0.12, 0.12, 1.5), (0, 0, 0.9), y)
    box((0.1, 1.5, 0.1), (0, 0.55, 1.75), y, (12, 0, 0))
    box((0.08, 0.08, 0.7), (0, 0.15, 1.1), dark(), (-20, 0, 0))  # ram
    box((0.03, 0.03, 0.5), (0, 1.25, 1.35), dark())  # chain
    box((0.55, 0.42, 0.45), (0, 1.25, 0.85), mat("engine", (0.35, 0.37, 0.38), "metal_05_128.png"))
    box((0.6, 0.2, 0.15), (0, 1.25, 1.12), dark())


def key_cabinet():
    k = mat("keybox", (0.45, 0.5, 0.45), "metal_05_128.png")
    box((0.5, 0.1, 0.6), (0, 0.05, 0.3), k)
    box((0.46, 0.01, 0.56), (0, 0.095, 0.3), dark())
    box((0.5, 0.02, 0.6), (0.48, 0.3, 0.3), k, (0, 0, 75))  # the door, swung open
    cols = [red(), yellow(), mat("blue", (0.1, 0.3, 0.8)), white()]
    for row in range(4):
        for i in range(6):
            x = -0.18 + i * 0.072
            z = 0.5 - row * 0.13
            box((0.01, 0.01, 0.03), (x, 0.11, z), steel())
            if (row * 7 + i) % 5 != 3:  # a few hooks empty
                box((0.03, 0.008, 0.045), (x, 0.115, z - 0.045), cols[(row + i) % 4])


def fuel_pump():
    box((0.7, 0.5, 0.15), (0, 0, 0.075), mat("plinth", (0.7, 0.7, 0.68), "concrete_128.png"))
    box((0.6, 0.4, 1.5), (0, 0, 0.9), red())
    box((0.5, 0.02, 0.35), (0, 0.205, 1.35), white())
    box((0.3, 0.01, 0.12), (0, 0.215, 1.4), glow((1, 0.6, 0.15), 1.5))
    box((0.64, 0.44, 0.08), (0, 0, 1.68), white())
    box((0.1, 0.12, 0.25), (0.33, 0.1, 1.0), dark())  # nozzle holster
    cyl(0.025, 0.9, (0.36, 0.2, 0.55), black())  # hose
    cyl(0.025, 0.4, (0.36, 0.42, 0.12), black(), (90, 0, 0))


# --- relay ---------------------------------------------------------------------------------------

def radio_rack():
    box((0.6, 0.6, 1.9), (0, 0, 0.95), mat("rack", (0.3, 0.32, 0.3), "metal_05_128.png"))
    for i, z in enumerate((0.35, 0.75, 1.15, 1.55)):
        box((0.54, 0.02, 0.32), (0, 0.305, z), dark())
        for j in range(4):
            cyl(0.025, 0.03, (-0.2 + j * 0.13, 0.32, z + 0.06), steel(), (90, 0, 0), v=8)
        c = [(0.2, 1, 0.3), (1, 0.65, 0.1), (0.2, 1, 0.3), (1, 0.15, 0.1)][i]
        box((0.2, 0.01, 0.07), (0.1, 0.32, z - 0.08), glow(c, 2.5))
        box((0.12, 0.01, 0.07), (-0.15, 0.32, z - 0.08), mat("meter", (0.85, 0.82, 0.6)))
    cyl(0.06, 0.4, (0.15, -0.15, 2.1), black())  # cables out of the top, to the mast
    cyl(0.04, 0.4, (0.05, -0.15, 2.1), black())


# --- lab -----------------------------------------------------------------------------------------

def fume_hood():
    w = white()
    box((1.5, 0.8, 0.88), (0, 0, 0.44), w)
    box((1.5, 0.8, 0.04), (0, 0, 0.9), black())
    box((0.06, 0.8, 1.38), (-0.72, 0, 1.6), w)
    box((0.06, 0.8, 1.38), (0.72, 0, 1.6), w)
    box((1.5, 0.06, 1.38), (0, -0.37, 1.6), w)
    box((1.5, 0.8, 0.5), (0, 0, 2.05), w)
    box((1.38, 0.02, 0.75), (0, 0.38, 1.3), glass())  # sash
    box((1.4, 0.05, 0.04), (0, 0.4, 1.68), steel())
    box((1.2, 0.02, 0.03), (0, 0.2, 1.78), glow((0.9, 0.95, 1.0), 2))
    cyl(0.18, 0.7, (0, -0.1, 2.65), steel())  # the exhaust duct
    for i, c in enumerate(((0.9, 0.5, 0.1), (0.2, 0.8, 0.3), (0.3, 0.5, 0.9))):
        cyl(0.05, 0.22, (-0.4 + i * 0.25, -0.1, 1.03), mat("reagent%d" % i, c, alpha=0.75, rough=0.2))
    box((1.2, 0.02, 0.06), (0, 0.41, 0.62), mat("label_yellow", (1, 0.8, 0.1)))


def lab_bench():
    w = white()
    box((2.4, 0.75, 0.86), (0, 0, 0.43), w)
    for x in (-0.9, -0.3, 0.3, 0.9):
        box((0.56, 0.01, 0.7), (x, 0.38, 0.45), mat("cabinet_door", (0.8, 0.82, 0.82), "panels_128.png"))
        box((0.12, 0.02, 0.02), (x, 0.39, 0.72), steel())
    box((2.44, 0.79, 0.04), (0, 0, 0.88), black())
    box((0.5, 0.36, 0.02), (0.75, 0.05, 0.895), steel())  # sink
    cyl(0.015, 0.35, (0.75, -0.18, 1.06), steel())
    box((0.015, 0.16, 0.015), (0.75, -0.1, 1.23), steel())
    box((2.3, 0.22, 0.03), (0, -0.25, 1.35), steel())  # reagent shelf
    for x in (-1.1, 1.1):
        box((0.03, 0.03, 0.47), (x, -0.25, 1.12), steel())
    cols = [(0.6, 0.35, 0.1), (0.2, 0.6, 0.3), (0.25, 0.4, 0.85), (0.85, 0.85, 0.85), (0.7, 0.2, 0.2)]
    for i in range(11):
        cyl(0.04, 0.16 + (i % 3) * 0.03, (-1.0 + i * 0.2, -0.25, 1.45 + (i % 3) * 0.015),
            mat("bottle%d" % (i % 5), cols[i % 5], alpha=0.8, rough=0.2), v=8)
    # glassware on the top: flasks and a tube rack
    for i, x in enumerate((-0.9, -0.65)):
        cyl(0.11, 0.2, (x, 0.1, 1.0), mat("flask", (0.75, 0.9, 0.85), alpha=0.5, rough=0.1), v=10, r2=0.03)
    box((0.3, 0.1, 0.08), (-0.2, 0.15, 0.94), steel())
    for i in range(6):
        cyl(0.012, 0.14, (-0.32 + i * 0.05, 0.15, 1.0), glow((0.3, 0.9, 1.0), 1.5), v=6)


def gas_cylinders():
    box((0.85, 0.35, 0.05), (0, 0, 0.025), dark())
    for i, c in enumerate(((0.15, 0.45, 0.2), (0.15, 0.25, 0.6), (0.55, 0.55, 0.55))):
        x = -0.27 + i * 0.27
        cyl(0.12, 1.35, (x, 0, 0.72), mat("gas%d" % i, c, "metal_05_128.png"))
        cyl(0.12, 0.12, (x, 0, 1.46), white(), r2=0.05)
        cyl(0.03, 0.12, (x, 0, 1.56), steel())
    box((0.9, 0.02, 0.04), (0, 0.13, 1.1), dark())  # the chain strap
    box((0.9, 0.04, 0.6), (0, -0.16, 1.0), dark())  # wall bracket


def specimen_fridge():
    w = white()
    box((0.75, 0.7, 1.95), (0, 0, 0.975), w)
    box((0.66, 0.02, 1.6), (0, 0.35, 0.95), glass())
    box((0.66, 0.6, 1.6), (0, -0.02, 0.95), mat("fridge_in", (0.55, 0.75, 0.85), emit=((0.5, 0.8, 1.0), 0.6)))
    for z in (0.45, 0.8, 1.15, 1.5):
        box((0.62, 0.5, 0.02), (0, 0.04, z), steel())
        for i in range(7):
            cyl(0.02, 0.1, (-0.24 + i * 0.08, 0.15, z + 0.06), glow([(1, 0.3, 0.2), (0.3, 1, 0.4), (0.3, 0.6, 1)][i % 3], 1.2), v=6)
    box((0.3, 0.02, 0.08), (0, 0.36, 1.85), glow((1, 0.15, 0.1), 2))
    box((0.03, 0.04, 0.5), (0.3, 0.38, 1.0), steel())


def glovebox():
    st = steel()
    for x in (-0.7, 0.7):
        for y in (-0.3, 0.3):
            box((0.05, 0.05, 0.9), (x, y, 0.45), st)
    box((1.6, 0.8, 0.06), (0, 0, 0.92), st)
    box((1.6, 0.8, 0.05), (0, 0, 1.75), st)
    box((1.6, 0.05, 0.8), (0, -0.38, 1.33), st)
    box((0.05, 0.8, 0.8), (-0.78, 0, 1.33), st)
    box((0.05, 0.8, 0.8), (0.78, 0, 1.33), st)
    box((1.5, 0.02, 0.76), (0, 0.39, 1.33), glass())
    for x in (-0.35, 0.35):
        torus(0.11, 0.025, (x, 0.4, 1.25), black(), (90, 0, 0), maj=12, mn=4)
        cyl(0.09, 0.35, (x, 0.22, 1.22), black(), (75, 0, 0))
    box((0.4, 0.3, 0.25), (0.45, -0.1, 1.08), glow((0.9, 0.3, 0.9), 0.6))  # a sample tray under UV
    box((0.3, 0.05, 0.12), (-0.6, 0.41, 1.88), mat("label_red", (0.8, 0.1, 0.1)))


def microscope():
    d = mat("scope", (0.92, 0.92, 0.9), "panels_128.png")
    box((0.22, 0.28, 0.04), (0, 0, 0.02), d)
    box((0.06, 0.06, 0.3), (0, -0.1, 0.17), d, (-10, 0, 0))
    box((0.16, 0.12, 0.02), (0, 0.03, 0.12), black())
    cyl(0.03, 0.18, (0, 0.02, 0.3), black(), (25, 0, 0))
    cyl(0.018, 0.1, (0, -0.04, 0.42), black(), (-30, 0, 0))


# --- vault and archive ---------------------------------------------------------------------------

def vault_door():
    st = mat("vault", (0.72, 0.72, 0.7), "metal_05_128.png")
    cyl(1.1, 0.45, (0, 0, 1.1), st, (90, 0, 0), v=20)
    cyl(0.85, 0.06, (0, 0.25, 1.1), mat("vault_face", (0.55, 0.55, 0.53), "metal_05_128.png"), (90, 0, 0), v=20)
    for i in range(12):
        a = math.radians(i * 30)
        cyl(0.07, 0.3, (math.cos(a) * 0.98, -0.3, 1.1 + math.sin(a) * 0.98), steel(), (90, 0, 0), v=8)  # bolts out of the edge
    torus(0.32, 0.04, (0, 0.38, 1.1), steel(), (90, 0, 0), maj=16, mn=6)
    for a in (0, 60, 120):
        box((0.64, 0.05, 0.05), (0, 0.38, 1.1), steel(), (0, a, 0))
    cyl(0.08, 0.2, (0, 0.32, 1.1), dark(), (90, 0, 0), v=10)
    box((0.3, 0.5, 0.9), (-1.15, 0, 1.1), dark())  # the hinge


def deposit_boxes():
    br = mat("deposit", (0.75, 0.62, 0.38), "metal_05_128.png")
    box((3.0, 0.5, 2.2), (0, 0, 1.1), dark())
    for row in range(8):
        for col in range(10):
            x = -1.35 + col * 0.3
            z = 0.2 + row * 0.26
            box((0.27, 0.03, 0.23), (x, 0.26, z), br)
            box((0.03, 0.01, 0.03), (x + 0.08, 0.28, z), black())
    box((0.27, 0.35, 0.05), (-0.75, 0.43, 0.98), br)  # one drawer pulled out


def filing_cabinet():
    f = mat("filing", (0.48, 0.5, 0.44), "metal_05_128.png")
    box((0.5, 0.65, 1.35), (0, 0, 0.675), f)
    for i in range(4):
        z = 0.2 + i * 0.32
        box((0.46, 0.02, 0.28), (0, 0.33, z), f)
        box((0.14, 0.03, 0.025), (0, 0.35, z + 0.06), steel())
        box((0.08, 0.01, 0.04), (0, 0.345, z + 0.11), white())
    box((0.46, 0.4, 0.28), (0, 0.5, 0.84), f)  # the third drawer open
    box((0.4, 0.3, 0.2), (0, 0.5, 0.95), mat("files", (0.85, 0.75, 0.5)))


# --- harbour and core ----------------------------------------------------------------------------

def on_deck(c, tilt, u, v, h):
    """A point h over a deck's top (centre c, tilted tilt degrees so its top faces +Y and up): u along x, v towards
    the front edge. Parts set on it take rotation (-tilt, 0, 0)."""
    t = math.radians(tilt)
    return (c[0] + u, c[1] + v * math.cos(t) + h * math.sin(t), c[2] - v * math.sin(t) + h * math.cos(t))


def control_panel():
    # fits LiftPanel (1.2 wide, 0.6 deep, 1.2 high): a console with a keypad deck sloping down to the front (+Y)
    box((1.2, 0.6, 0.15), (0, 0, 0.075), hazard())
    box((1.1, 0.5, 0.85), (0, -0.02, 0.57), mat("console", (0.42, 0.45, 0.48), "metal_05_128.png"))
    t, d = 25, (0, -0.02, 1.07)
    box((1.1, 0.12, 0.2), (0, -0.21, 1.08), mat("console", (0.42, 0.45, 0.48), "metal_05_128.png"))  # the raised back
    box((1.1, 0.5, 0.06), d, dark(), (-t, 0, 0))
    box((0.4, 0.26, 0.02), on_deck(d, t, -0.28, -0.02, 0.035), glow((0.3, 1, 0.45), 2.5), (-t, 0, 0))  # the screen
    for r in range(4):
        for c in range(3):
            box((0.05, 0.04, 0.02), on_deck(d, t, 0.12 + c * 0.07, 0.12 - r * 0.07, 0.035), white(), (-t, 0, 0))
    cyl(0.05, 0.05, on_deck(d, t, 0.42, 0.06, 0.05), red(), (-t, 0, 0))
    box((1.1, 0.04, 0.12), (0, 0.24, 0.92), yellow())
    box((0.06, 0.06, 0.08), (0.45, -0.22, 1.22), glow((1, 0.4, 0.1), 3))


def core_console():
    # fits ConsoleDesk in the Core room (3 long, 1.2 deep, 1 high); front +Y faces the room, the deck slopes to it
    c = mat("core_metal", (0.22, 0.23, 0.26), "metal_05_128.png")
    box((3.0, 1.0, 0.75), (0, -0.1, 0.375), c)
    t, d = 20, (0, 0.12, 0.84)
    box((3.0, 0.6, 0.06), d, dark(), (-t, 0, 0))
    for i in range(24):
        x = -1.35 + (i % 12) * 0.245
        col = [(1, 0.15, 0.1), (0.2, 1, 0.3), (1, 0.7, 0.1)][i % 3]
        box((0.12, 0.08, 0.02), on_deck(d, t, x, 0.1 - (i // 12) * 0.18, 0.035), glow(col, 2), (-t, 0, 0))
    box((2.9, 0.04, 0.06), (0, 0.42, 0.7), glow((1, 0.1, 0.05), 3))
    box((3.0, 0.2, 1.0), (0, -0.5, 0.5), c)


def mainframe():
    c = mat("frame_metal", (0.3, 0.31, 0.34), "metal_05_128.png")
    for i in range(3):
        x = -1.0 + i * 1.0
        box((0.96, 0.8, 2.6), (x, 0, 1.3), c)
        for j, cx in enumerate((-0.2, 0.2)):  # tape reels
            torus(0.14, 0.03, (x + cx, 0.41, 1.95), dark(), (90, 0, 0), maj=12, mn=4)
            cyl(0.05, 0.02, (x + cx, 0.41, 1.95), steel(), (90, 0, 0), v=8)
        box((0.8, 0.02, 0.34), (x, 0.405, 1.95), glass())
        for r in range(6):
            col = [(1, 0.15, 0.1), (0.2, 1, 0.3), (1, 0.7, 0.1)][(r + i) % 3]
            box((0.7, 0.02, 0.03), (x, 0.405, 0.4 + r * 0.17), glow(col, 1.5 + (r % 2)))
    box((3.0, 0.8, 0.12), (0, 0, 2.66), dark())


def pump():
    sk = mat("skid", (0.25, 0.3, 0.28), "metal_05_128.png")
    box((1.5, 0.7, 0.12), (0, 0, 0.06), sk)
    cyl(0.25, 0.7, (-0.35, 0, 0.42), mat("motor", (0.2, 0.42, 0.45), "metal_05_128.png"), (0, 90, 0))
    cyl(0.3, 0.25, (0.25, 0, 0.42), mat("volute", (0.6, 0.15, 0.12), "metal_05_128.png"), (0, 90, 0))
    cyl(0.1, 0.9, (0.25, 0, 1.1), steel())
    cyl(0.1, 0.5, (0.55, 0, 0.42), steel(), (0, 90, 0))
    torus(0.14, 0.025, (0.25, 0.12, 1.2), red(), (90, 0, 0), maj=12, mn=4)


def boom_gate():
    box((0.45, 0.45, 1.1), (0, 0, 0.55), yellow())
    box((0.5, 0.5, 0.06), (0, 0, 1.13), black())
    box((0.3, 0.2, 0.3), (0, 0, 1.3), dark())  # pivot housing
    # the arm, raised (the gate is open): red and white bands
    for i in range(10):
        m = red() if i % 2 == 0 else white()
        box((0.1, 0.1, 0.48), (0, 0.22, 1.5 + i * 0.48), m)
    box((0.25, 0.2, 0.3), (0, 0.22, 1.15), dark())  # counterweight


def life_ring():
    o = mat("orange", (1.0, 0.4, 0.05), "metal_05_128.png")
    for i in range(8):
        a = i * 45
        r = math.radians(a + 22.5)
        torus(0.3, 0.075, (0, 0.08, 0.38), o if i % 2 == 0 else white(), (90, 0, 0), maj=16, mn=6)
        break
    for a in (0, 90, 180, 270):  # white bands
        r = math.radians(a)
        box((0.17, 0.17, 0.08), (math.cos(r) * 0.3, 0.08, 0.38 + math.sin(r) * 0.3), white(), (0, -a, 0))
    box((0.08, 0.06, 0.12), (0, 0.02, 0.72), dark())  # the hook


def strip_curtain():
    box((2.0, 0.1, 0.1), (0, 0, 2.55), steel())
    s = mat("pvc", (0.75, 0.88, 0.95), alpha=0.35, rough=0.2)
    for i in range(9):
        box((0.21, 0.01, 2.45), (-0.89 + i * 0.2225, 0.04 if i % 2 else -0.04, 1.27), s)


def conveyor():
    fr = mat("conv_frame", (0.85, 0.55, 0.1), "metal_05_128.png")
    ang = math.degrees(math.atan2(5.0, 10.0))
    L = math.hypot(10, 5)
    box((0.9, L, 0.25), (0, 5, 2.5), fr, (ang, 0, 0))
    box((0.7, L, 0.05), (0, 5, 2.65), rubber(), (ang, 0, 0))
    for y in (1.5, 4.5, 7.5):
        h = y * 0.5
        for x in (-0.4, 0.4):
            box((0.1, 0.1, h), (x, y, h / 2), fr)
    box((1.6, 1.6, 1.0), (0, -0.4, 0.5), mat("hopper", (0.4, 0.4, 0.38), "rust_128.png"))
    for i in range(6):
        y = 1.2 + i * 1.5
        box((0.35, 0.3, 0.15), (0.05, y, y * 0.5 + 0.2), mat("gravel_bits", (0.55, 0.52, 0.48), "rock_128.png"), (ang, 0, i * 20))


def biohazard_bin():
    cyl(0.25, 0.6, (0, 0, 0.3), yellow(), v=12)
    cyl(0.27, 0.06, (0, 0, 0.63), red(), v=12)
    box((0.22, 0.01, 0.22), (0, 0.25, 0.32), black())


def whiteboard():
    box((1.8, 0.04, 1.0), (0, 0.02, 0.5), mat("board", (0.95, 0.96, 0.96)))
    box((1.86, 0.05, 0.04), (0, 0.025, 1.02), steel())
    box((1.86, 0.05, 0.04), (0, 0.025, -0.02), steel())
    box((1.6, 0.08, 0.03), (0, 0.06, 0.0), steel())
    ink = mat("ink", (0.1, 0.2, 0.6))
    for i in range(6):
        box((0.3 + (i % 3) * 0.2, 0.005, 0.015), (-0.5 + (i % 2) * 0.4, 0.045, 0.85 - i * 0.1), ink)
    torus(0.15, 0.01, (0.5, 0.045, 0.55), mat("ink_red", (0.7, 0.1, 0.1)), (90, 0, 0), maj=16, mn=3)


def notice_board():
    box((1.2, 0.03, 0.8), (0, 0.015, 0.4), mat("cork", (0.75, 0.52, 0.3), "wood_07_128.png"))
    p = mat("paper", (0.92, 0.9, 0.82))
    for i, (x, z) in enumerate(((-0.4, 0.55), (-0.1, 0.6), (0.25, 0.5), (-0.3, 0.2), (0.15, 0.2), (0.42, 0.25))):
        box((0.2, 0.005, 0.26), (x, 0.035, z), p, (0, (i % 3 - 1) * 4, 0))
        box((0.02, 0.01, 0.02), (x, 0.04, z + 0.11), red())


def counter():
    w = mat("counter_body", (0.7, 0.68, 0.62), "panels_128.png")
    box((2.4, 0.65, 0.88), (0, 0, 0.44), w)
    box((2.44, 0.68, 0.04), (0, 0, 0.9), steel())
    box((0.6, 0.5, 0.04), (-0.7, 0, 0.93), black())  # stove top
    for x, y in ((-0.85, -0.12), (-0.55, -0.12), (-0.85, 0.12), (-0.55, 0.12)):
        torus(0.08, 0.012, (x, y, 0.955), dark(), maj=10, mn=3)
    box((0.45, 0.35, 0.02), (0.55, 0.0, 0.915), dark())  # sink
    cyl(0.12, 0.2, (-0.7, 0.05, 1.05), steel())  # a pot
    cyl(0.07, 0.22, (0.0, -0.1, 1.03), mat("coffee", (0.3, 0.3, 0.32)), v=10)
    for x in (-0.9, -0.3, 0.3, 0.9):
        box((0.56, 0.01, 0.7), (x, 0.33, 0.45), mat("counter_door", (0.6, 0.58, 0.5), "panels_128.png"))


def low_cabinets():
    # indoor low cover (area_kit.gd ROWS "Cabinets"): a run of drawers both sides, 1 m tall, a dark top
    body = mat("low_body", (0.8, 0.82, 0.83), "panels_128.png")
    box((2.0, 0.8, 0.94), (0, 0, 0.47), body)
    box((2.04, 0.84, 0.06), (0, 0, 0.97), black())
    for y in (-0.405, 0.405):
        for x in (-0.75, -0.25, 0.25, 0.75):
            box((0.46, 0.01, 0.38), (x, y, 0.68), mat("low_front", (0.7, 0.72, 0.74), "panels_128.png"))
            box((0.46, 0.01, 0.38), (x, y, 0.26), mat("low_front", (0.7, 0.72, 0.74), "panels_128.png"))
            box((0.14, 0.02, 0.02), (x, y * 1.04, 0.8), steel())
            box((0.14, 0.02, 0.02), (x, y * 1.04, 0.38), steel())


MODELS = {k: v for k, v in globals().items() if callable(v) and k not in (
    "mat", "box", "cyl", "torus", "finish", "on_deck", "steel", "dark", "black", "white", "yellow", "red", "rubber", "wood",
    "hazard", "glass", "glow") and not k.startswith("_")}

bpy.ops.wm.read_factory_settings(use_empty=True)
for name, fn in MODELS.items():
    if ONLY and name not in ONLY:
        continue
    fn()
    finish(name)
if not ONLY:  # a partial file would overwrite the full one
    bpy.ops.wm.save_as_mainfile(filepath=ROOT + "/_raw/blender/identity_props.blend")
