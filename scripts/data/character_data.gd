extends Resource
class_name CharacterData

@export var id: String = ""
@export var display_name: String = ""

## Why this character is on the road to Hanyang.
@export_multiline var motivation: String = ""

## The rumor about the incident brewing in Hanyang that this character
## overhears after their first fight. Each character hears a different
## angle on the same underlying event.
@export_multiline var clue_text: String = ""

@export var starting_hp: int = 70
@export var starting_deck: Array[String] = []
@export var portrait: Texture2D = null
