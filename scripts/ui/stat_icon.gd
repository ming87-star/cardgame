extends Control
class_name StatIcon

## Small flat vector icon so status effects and enemy intent read as shapes,
## not just numbers -- no image assets needed.
enum Kind { BLOCK, WEAK, VULNERABLE, STRENGTH, ATTACK, BUFF, WEAKEN }

@export var kind: Kind = Kind.BLOCK:
	set(v):
		kind = v
		queue_redraw()
@export var icon_color: Color = Color.WHITE:
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

func _draw_sword() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(w * 0.44, h * 0.02, w * 0.12, h * 0.56), icon_color)
	draw_rect(Rect2(w * 0.22, h * 0.54, w * 0.56, h * 0.1), icon_color)
	draw_rect(Rect2(w * 0.4, h * 0.64, w * 0.2, h * 0.32), icon_color)
