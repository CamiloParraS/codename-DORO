## An Area's walkable floor seen from above, from its baked navmesh (the NavRegion every builder bakes): the
## blueprint the "What Aigis saw" page draws the route over. Diagram metres (MissionPlaces), like the route.
## {tris: flat triangles [a, b, c, ...] for one fill, edges: segment pairs on the floor's outline (an edge only
## one polygon has), lo / hi: the bounds}. Built once, as the post-Mission screen opens; never saved.
class_name FloorPlan
extends RefCounted


## The floor of every NavigationRegion3D under `area`, or {} with none.
static func of_area(area: Node) -> Dictionary:
	var tris := PackedVector2Array()
	var edges := PackedVector2Array()
	if area:
		for r: NavigationRegion3D in area.find_children("*", "NavigationRegion3D", true, false):
			if r.navigation_mesh:
				var nm := r.navigation_mesh
				var polys: Array[PackedInt32Array] = []
				for i in nm.get_polygon_count():
					polys.append(nm.get_polygon(i))
				var one := from_mesh(nm.get_vertices(), polys, r.global_transform)
				tris.append_array(one.tris)
				edges.append_array(one.edges)
	return _bounded(tris, edges)


## One navmesh's floor: verts in the region's space, polys as vertex indices (convex, as Godot bakes them).
static func from_mesh(verts: PackedVector3Array, polys: Array[PackedInt32Array], xf := Transform3D.IDENTITY) -> Dictionary:
	var flat := PackedVector2Array()
	for v in verts:
		flat.append(MissionPlaces.diagram_xy(xf * v))
	var tris := PackedVector2Array()
	var count := {}  # "a:b" (a < b) -> [a, b, how many polygons share the edge]
	for p in polys:
		for i in range(1, p.size() - 1):  # a fan: the polygons are convex
			tris.append_array([flat[p[0]], flat[p[i]], flat[p[i + 1]]])
		for i in p.size():
			var a := mini(p[i], p[(i + 1) % p.size()])
			var b := maxi(p[i], p[(i + 1) % p.size()])
			var k := "%d:%d" % [a, b]
			count[k] = [a, b, count[k][2] + 1] if count.has(k) else [a, b, 1]
	var edges := PackedVector2Array()
	for k: String in count:
		if count[k][2] == 1:
			edges.append_array([flat[count[k][0]], flat[count[k][1]]])
	return _bounded(tris, edges)


static func _bounded(tris: PackedVector2Array, edges: PackedVector2Array) -> Dictionary:
	if tris.is_empty():
		return {}
	var box := Rect2(tris[0], Vector2.ZERO)
	for p in tris:
		box = box.expand(p)
	return {tris = tris, edges = edges, lo = box.position, hi = box.end}
