extends Control
class_name GroundMarker

## Soft ellipse under a figure's feet. Doubles as the drop-target indicator:
## it lights up while a card that can land on this figure is being dragged.

const REST_COLOR := Color(0.149, 0.133, 0.114, 0.12)
const TARGET_COLOR := Color(0.7, 0.28, 0.16, 0.42)
const AFFECTED_COLOR := Color(0.29, 0.365, 0.51, 0.45)

enum State { REST, TARGET, AFFECTED }

var state: State = State.REST:
	set(v):
		state = v
		queue_redraw()

func _draw() -> void:
	var color: Color = REST_COLOR
	match state:
		State.TARGET:
			color = TARGET_COLOR
		State.AFFECTED:
			color = AFFECTED_COLOR

	var center := size * 0.5
	var points := PackedVector2Array()
	for i in range(28):
		var angle: float = i * TAU / 28.0
		points.append(center + Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5))
	draw_colored_polygon(points, color)
