@icon("res://addons/dialogue_nodes/icons/Character.svg")
extends Resource
class_name Character

@export var name : String = ''
@export var editorName: String = ''
@export var image : Texture2D
@export var color : Color = Color.WHITE
@export var states : Array[CharacterState]
