## The Harbour Area (greybox). Marker groups: spot, sentry_high_point, camera_mount, guard_post,
## guard_post_extra, spoof_place. A guard post's child markers are its patrol route.
## Open harbour.tscn and press F6.
extends Node3D

const GUARD := preload("res://actors/guard/guard.tscn")
const BASE_GUARDS := 10  # the remaining posts are left for Countermeasure extras


func _ready() -> void:
	for post: Marker3D in $GuardPosts.get_children().slice(0, BASE_GUARDS):
		spawn_guard(post)


func spawn_guard(post: Marker3D) -> Node3D:
	var g := GUARD.instantiate()
	g.name = post.name.replace("Post", "Guard")
	g.route.append(post.global_position)
	for wp: Marker3D in post.get_children():
		g.route.append(wp.global_position)
	g.target = $Operative
	add_child(g)
	g.global_transform = post.global_transform
	return g
