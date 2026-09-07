extends Control
class_name StatIcon

## Small flat vector icon so status effects and enemy intent read as shapes,
## not just numbers -- no image assets needed.
enum Kind { BLOCK, WEAK, VULNERABLE, STRENGTH, ATTACK, BUFF, WEAKEN, ADVANCE, AIM, ROOT }

@export var kind: Kind = Kind.BLOCK:
	set(v):
		kind = v
		queue_redraw()
@export var icon_color: Color = Color(0.149, 0.133, 0.114):
	set(v):
		icon_color = v
		queue_redraw()

func _draw() -> void:
	match kind:
		Kind.BLOCK:
			_draw_shield()
		Kind.WEAK, Kind.WEAKEN:
			_draw_chevron(false)
		Kind.VULNERABLE:
			_draw_burst()
		Kind.STRENGTH, Kind.BUFF:
			_draw_chevron(true)
		Kind.ATTACK:
			_draw_sword()
		Kind.ADVANCE:
			_draw_advance()
		Kind.AIM:
			_draw_aim()
		Kind.ROOT:
			_draw_root()

func _draw_shield() -> void:
	var w := size.x
	var h := size.y
	var pts := PackedVector2Array([
		Vector2(w * 0.5, 0), Vector2(w, h * 0.22), Vector2(w, h * 0.55),
		Vector2(w * 0.5, h), Vector2(0, h * 0.55), Vector2(0, h * 0.22),
	])
	draw_colored_polygon(pts, icon_color)

func _draw_chevron(pointing_up: bool) -> void:
	var w := size.x
	var h := size.y
	var top := h * 0.22 if pointing_up else h * 0.78
	var mid := h * 0.78 if pointing_up else h * 0.22
	var pts := PackedVector2Array([
		Vector2(w * 0.12, top), Vector2(w * 0.5, mid), Vector2(w * 0.88, top),
	])
	draw_polyline(pts, icon_color, max(w, h) * 0.18, true)

func _draw_burst() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var cy := h * 0.5
	var r1: float = min(w, h) * 0.5
	var r2: float = r1 * 0.42
	var pts := PackedVector2Array()
	for i in range(8):
		var ang := i * PI / 4.0
		var r: float = r1 if i % 2 == 0 else r2
		pts.append(Vector2(cx + cos(ang) * r, cy + sin(ang) * r))
	draw_colored_polygon(pts, icon_color)

## Enemy closing the gap: a leftward arrow, since enemies come up the road
## from the right.
func _draw_advance() -> void:
	var w := size.x
	var h := size.y
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.05, h * 0.5), Vector2(w * 0.5, h * 0.12),
		Vector2(w * 0.5, h * 0.88),
	]), icon_color)
	draw_rect(Rect2(w * 0.5, h * 0.34, w * 0.45, h * 0.32), icon_color)

## 저지: a barred line the enemy cannot step past.
func _draw_root() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(w * 0.42, 0, w * 0.16, h), icon_color)
	draw_rect(Rect2(w * 0.06, h * 0.30, w * 0.30, h * 0.14), icon_color)
	draw_rect(Rect2(w * 0.06, h * 0.56, w * 0.30, h * 0.14), icon_color)

## 선비's 조준 stack: concentric rings, a target held steady.
func _draw_aim() -> void:
	var center := size * 0.5
	var radius: float = min(size.x, size.y) * 0.5
	draw_arc(center, radius * 0.9, 0.0, TAU, 20, icon_color, radius * 0.18, true)
	draw_circle(center, radius * 0.3, icon_color)

func _draw_sword() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(w * 0.44, h * 0.02, w * 0.12, h * 0.56), icon_color)
	draw_rect(Rect2(w * 0.22, h * 0.54, w * 0.56, h * 0.1), icon_color)
	draw_rect(Rect2(w * 0.4, h * 0.64, w * 0.2, h * 0.32), icon_color)
