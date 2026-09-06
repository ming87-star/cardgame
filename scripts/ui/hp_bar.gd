extends Control
class_name HPBar

## A gauge drawn as a single brush stroke rather than a filled box: the bar
## tapers to a point at each end and its edge wavers slightly, so it reads as
## one confident stroke of ink laid on the paper. Sits directly on the
## background with no panel behind it, so the value text carries an outline.

const TRACK_COLOR := Color(0.149, 0.133, 0.114, 0.16)
const STEPS := 28

@export var fill_color: Color = Color(0.478, 0.29, 0.2)

var _ratio: float = 1.0
var _text: String = "0/0"
## Per-instance phase, so neighbouring gauges don't waver in unison.
var _phase: float = 0.0

@onready var value_label: Label = %ValueLabel

func _ready() -> void:
	_phase = randf() * TAU
	value_label.text = _text
	queue_redraw()

func set_values(current: int, max_value: int) -> void:
	_ratio = 0.0 if max_value <= 0 else clampf(float(current) / float(max_value), 0.0, 1.0)
	_text = "%d/%d" % [current, max_value]
	if value_label:
		value_label.text = _text
	queue_redraw()

func set_fill_color(color: Color) -> void:
	fill_color = color
	queue_redraw()

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	draw_colored_polygon(_stroke(1.0), TRACK_COLOR)
	if _ratio > 0.0:
		draw_colored_polygon(_stroke(_ratio), fill_color)

## Half-thickness of the stroke at `t` along its full length. The shallow
## exponent keeps the middle almost flat and puts the taper at the very ends,
## which is what a loaded brush actually leaves behind.
func _half_height(t: float) -> float:
	var taper: float = pow(sin(PI * clampf(t, 0.0, 1.0)), 0.30)
	var waver: float = 1.0 + 0.12 * sin(t * 11.0 + _phase) + 0.06 * sin(t * 23.0 + _phase * 2.0)
	return size.y * 0.42 * taper * waver

## Outline of the stroke from the left end up to `upto` (0..1). A partial
## stroke stops bluntly at its current thickness, so a half-full gauge looks
## like ink that ran out mid-sweep.
func _stroke(upto: float) -> PackedVector2Array:
	var mid: float = size.y * 0.5
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in range(STEPS + 1):
		var t: float = (float(i) / float(STEPS)) * upto
		var x: float = t * size.x
		var half: float = _half_height(t)
		top.append(Vector2(x, mid - half))
		bottom.append(Vector2(x, mid + half))
	bottom.reverse()
	var points := top
	points.append_array(bottom)
	return points
