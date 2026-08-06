extends Resource
class_name Background

@export var name : String
## Path to the background image (e.g. "res://data/background_lists/.../bg.png").
## Stored as a path instead of a Texture so loading a BackgroundList does NOT
## load every image up front; textures are loaded on demand via getTexture().
@export var imagePath : String
@export var wallpaperId : String

# Runtime-only texture, used by code that builds Backgrounds on the fly
# (e.g. DateActionResult.setBackground). Never serialized to .tres files.
var images : Texture

func getTexture() -> Texture2D:
	if images:
		return images
	if imagePath != '':
		return BackgroundCache.getTexture(imagePath)
	return null
