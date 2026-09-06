extends Control
class_name FigureAnim

## Drives every bit of motion for one battlefield figure (player or enemy).
##
## Deliberately not sprite-sheet based: the ink-wash figures are single painted
## images, so an idle "breath" is synthesised here (bob + vertical squash about
## the feet) instead of flipping frames, which keeps the brushwork from
## jittering. Discrete pose *changes* (idle/attack/guard) are separate textures
## swapped in by the owning figure.
##
## Must be a full-rect-anchored child of a plain Control (never a Container),
## so nothing re-lays it out while the tweens own `position`.

const HOME := Vector2.ZERO

@export var idle_speed: float = 1.5
@export var bob_pixels: float = 3.0

var _phase: float = 0.0
var _acting: bool = false

func _ready() -> void:
	# Random phase so a row of enemies doesn't breathe in lockstep.
	_phase = randf() * TAU
	resized.connect(_recentre_pivot)
	_recentre_pivot()

func _recentre_pivot() -> void:
	pivot_offset = Vector2(size.x * 0.5, size.y)

func _process(delta: float) -> void:
	if _acting:
		return
	_phase += delta * idle_speed
	position = HOME + Vector2(0, sin(_phase) * bob_pixels)
	scale = Vector2(1.0, 1.0 + sin(_phase * 0.9) * 0.015)

## Steps toward the target and back. `dir` is +1 to lunge right, -1 for left.
func lunge(dir: int) -> void:
	_acting = true
	var tw := create_tween()
	tw.tween_property(self, "position", HOME + Vector2(38 * dir, -7), 0.13) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", HOME, 0.24) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	_reset()

## Knocked back away from the blow. `dir` is the direction the hit travels.
func hit_react(dir: int) -> void:
	_acting = true
	var tw := create_tween()
	tw.tween_property(self, "position", HOME + Vector2(16 * dir, 0), 0.06)
	tw.tween_property(self, "position", HOME + Vector2(-9 * dir, 0), 0.07)
	tw.tween_property(self, "position", HOME, 0.12)
	await tw.finished
	_reset()

## Small upward pop for buffs/block, so non-damage actions still read.
func pulse() -> void:
	_acting = true
	var tw := create_tween()
	tw.tween_property(self, "position", HOME + Vector2(0, -12), 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", HOME, 0.18) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_reset()

func _reset() -> void:
	position = HOME
	scale = Vector2.ONE
	_acting = false
