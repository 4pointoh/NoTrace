extends Resource
class_name BackgroundFocus

## A point of interest in a background picture, usually a face, that the camera can frame in
## the landscape frame. For now the reveal uses it: name one in the stage's reveal config
## (focusName) and the reveal holds on it before the frame opens.

@export var name : String
## Where it is in the picture: (0, 0) is the top-left corner, (1, 1) the bottom-right.
@export var point := Vector2(0.5, 0.5)
## How far to push in. 1 is the whole picture. Much past 1.3 looks soft unless the art is
## larger than the 1920x1080 frame.
@export_range(1.0, 3.0, 0.05) var zoom := 1.45
