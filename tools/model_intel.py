# The intel pickup's model: a classified dossier, cover lifted on its papers, a photo clipped to it.
# PSX-sized (about 100 tris) on one 128 px texture painted here, sampled nearest. Writes assets/models/props/intel_dossier.glb:
#   blender -b --python tools/model_intel.py
# Rerun after changing it; areas/objective_marker.gd loads the glb.
import bpy, bmesh, math, random, os

D = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/") + "/"
OUT = D + "assets/models/props/intel_dossier.glb"
N = 128
random.seed(7)

# ---- the texture: regions in pixels, x right and y up (Blender's image rows run bottom to top) ----
COVER = (0, 80, 64, 48)     # x, y, w, h: the front cover's face
INSIDE = (64, 80, 64, 48)   # the cover's inside and the back cover's underside
PAPER = (0, 32, 64, 48)     # the top sheet
PHOTO = (64, 40, 32, 24)    # the clipped photo
EDGE_MANILA = (96, 56, 8, 8)
EDGE_PAPER = (104, 56, 8, 8)
METAL = (112, 56, 8, 8)
RED = (120, 56, 8, 8)

px = [0.0] * (N * N * 4)


def put(x, y, c):
    if 0 <= x < N and 0 <= y < N:
        i = (y * N + x) * 4
        px[i:i + 4] = [c[0], c[1], c[2], 1.0]


def fill(r, c, grain=0.0):
    x0, y0, w, h = r
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            k = 1.0 + random.uniform(-grain, grain)
            put(x, y, [min(1, v * k) for v in c])


def rect(x0, y0, w, h, c):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            put(x, y, c)


def frame(x0, y0, w, h, c):
    for x in range(x0, x0 + w):
        put(x, y0, c); put(x, y0 + h - 1, c)
    for y in range(y0, y0 + h):
        put(x0, y, c); put(x0 + w - 1, y, c)


# 3x5 pixel font, rows top to bottom
FONT = {
    "T": ["111", "010", "010", "010", "010"], "O": ["111", "101", "101", "101", "111"],
    "P": ["111", "101", "111", "100", "100"], "S": ["111", "100", "111", "001", "111"],
    "E": ["111", "100", "110", "100", "111"], "C": ["111", "100", "100", "100", "111"],
    "R": ["110", "101", "110", "101", "101"], "-": ["000", "000", "111", "000", "000"],
    "7": ["111", "001", "010", "010", "010"], "4": ["101", "101", "111", "001", "001"],
    "A": ["010", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"],
    "G": ["111", "100", "101", "101", "111"], " ": ["000"] * 5,
}


def text(s, x0, ytop, c):
    for k, ch in enumerate(s):
        for row, bits in enumerate(FONT[ch]):
            for col, b in enumerate(bits):
                if b == "1":
                    put(x0 + k * 4 + col, ytop - row, c)


MANILA = (0.80, 0.66, 0.40)
MANILA_DK = (0.58, 0.45, 0.25)
INK_RED = (0.72, 0.10, 0.08)
PAPER_C = (0.93, 0.91, 0.85)
INK = (0.25, 0.25, 0.28)

# cover: manila with a darker rim, a white label, a red TOP SECRET stamp and a red diagonal band
fill(COVER, MANILA, 0.05)
frame(0, 80, 64, 48, MANILA_DK)
rect(6, 114, 30, 8, PAPER_C); frame(6, 114, 30, 8, INK)
for x in range(9, 32, 1):
    if x % 5 != 4:
        put(x, 118, INK)
frame(8, 92, 48, 11, INK_RED); frame(9, 93, 46, 9, INK_RED)
text("TOP SECRET", 12, 100, INK_RED)
for i in range(16):  # the corner band, top right
    for t in range(4):
        put(48 + i, 127 - i - t, INK_RED)
text("AIGIS", 40, 87, INK)

fill(INSIDE, MANILA_DK, 0.05)
frame(64, 80, 64, 48, (0.48, 0.36, 0.2))

# paper: typed lines, a header, a redacted bar and a red classification strip
fill(PAPER, PAPER_C, 0.02)
rect(0, 77, 64, 3, INK_RED)
text("74-A", 4, 73, INK)
for y in range(66, 36, -3):
    w = random.randint(34, 56)
    for x in range(4, 4 + w):
        if random.random() > 0.12:
            put(x, y, (0.42, 0.42, 0.45))
rect(14, 54, 26, 2, (0.05, 0.05, 0.06))
rect(30, 45, 18, 2, (0.05, 0.05, 0.06))

# photo: white border, a cold grey print of a figure against a wall
fill(PHOTO, (0.95, 0.95, 0.92))
rect(66, 44, 28, 18, (0.30, 0.34, 0.38))
rect(66, 44, 28, 6, (0.22, 0.24, 0.27))
for y in range(44, 58):  # shoulders and head
    for x in range(66, 94):
        dx, dy = x - 80, y - 54
        if dx * dx + dy * dy * 1.4 < 14 or (y < 50 and abs(dx) < 8 - (50 - y) * 0.2):
            put(x, y, (0.12, 0.13, 0.15))
rect(66, 41, 28, 2, (0.95, 0.95, 0.92))

fill(EDGE_MANILA, MANILA_DK)
fill(EDGE_PAPER, (0.86, 0.84, 0.78))
for y in range(56, 64, 2):
    rect(104, y, 8, 1, (0.74, 0.72, 0.67))
fill(METAL, (0.70, 0.72, 0.75))
fill(RED, INK_RED)

bpy.ops.wm.read_factory_settings(use_empty=True)
img = bpy.data.images.new("intel_dossier", N, N, alpha=False)
img.pixels[:] = px
img.filepath_raw = D + "_raw/intel_dossier.png"
img.file_format = "PNG"
img.pack()

mat = bpy.data.materials.new("intel_dossier")
nt = mat.node_tree
bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = "Closest"
nt.links.new(tex.outputs[0], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.85


def uv_of(r, u, v):
    x0, y0, w, h = r
    return ((x0 + 0.5 + u * (w - 1)) / N, (y0 + 0.5 + v * (h - 1)) / N)


def slab(name, size, loc, rot_z=0.0, top=COVER, bottom=INSIDE, side=EDGE_MANILA, hinge=None):
    """A box of `size` (x, y, z metres) at `loc` (its bottom centre), turned rot_z degrees; hinge = (x, angle)
    lifts it about a line along y at local x (the spine), the free edge rising."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size[0]; v.co.y *= size[1]; v.co.z = (v.co.z + 0.5) * size[2]
    uv = bm.loops.layers.uv.new()
    for f in bm.faces:
        n = f.normal
        r = top if n.z > 0.5 else bottom if n.z < -0.5 else side
        for l in f.loops:
            co = l.vert.co
            u = co.x / size[0] + 0.5
            w = co.y / size[1] + 0.5
            if n.z < -0.5:
                u = 1 - u
            if abs(n.z) <= 0.5:
                u, w = (u if abs(n.y) > 0.5 else w), co.z / size[2]
            l[uv].uv = uv_of(r, u, w)
    if hinge:
        hx, ang = hinge
        a = math.radians(ang)
        for v in bm.verts:
            x, z = v.co.x - hx, v.co.z
            v.co.x = hx + x * math.cos(a) - z * math.sin(a)
            v.co.z = x * math.sin(a) + z * math.cos(a)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    o.data.materials.append(mat)
    o.location = loc
    o.rotation_euler.z = math.radians(rot_z)
    bpy.context.scene.collection.objects.link(o)
    return o


W, L, T = 0.34, 0.25, 0.006  # the folder: across, deep, card thickness
slab("Back", (W, L, T), (0, 0, 0), top=INSIDE, bottom=INSIDE)
slab("Papers", (W - 0.025, L - 0.016, 0.018), (0.012, 0.004, T), 3.0, top=PAPER, bottom=PAPER, side=EDGE_PAPER)
slab("Sheet", (W - 0.04, L - 0.03, 0.002), (0.028, -0.008, T + 0.018), -4.0, top=PAPER, bottom=PAPER, side=EDGE_PAPER)
slab("Cover", (W, L, T), (0, 0, T + 0.020), 0.0, hinge=(-W / 2, 9.0))
slab("Tab", (0.08, 0.022, T), (-0.06, L / 2 + 0.011, 0), top=EDGE_MANILA, bottom=EDGE_MANILA)
# the photo lies on the lifted cover: follow its slope at the photo's x
px0 = 0.07
cover_z = T + 0.020 + T + (px0 + W / 2) * math.sin(math.radians(9.0))
photo = slab("Photo", (0.085, 0.065, 0.002), (px0, 0.035, cover_z), 11.0, top=PHOTO, bottom=EDGE_PAPER, side=EDGE_PAPER)
photo.rotation_euler.y = -math.radians(9.0)
clip = slab("Clip", (0.012, 0.03, 0.004), (px0 - 0.01, 0.075, cover_z + 0.001), 11.0, top=METAL, bottom=METAL, side=METAL)
clip.rotation_euler.y = -math.radians(9.0)

# one mesh, centred on its bounding box's floor
for o in bpy.context.scene.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Back"]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.object.join()
o = bpy.context.view_layer.objects.active
o.name = "IntelDossier"
tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_apply=True)
print("wrote", OUT, "tris", tris)
