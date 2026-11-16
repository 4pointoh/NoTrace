extends Resource
class_name LandscapeRevealConfig

## What one portrait -> landscape reveal shows and plays. Make one, set it on the GameStage
## as `reveal`, and trigger it from dialogue with the signal reveal_landscape. The picture it
## opens onto is the background of the dialogue line that follows the signal.
##
## The sequence and its timing live in landscape_reveal.gd; the look lives in LandscapeReveal.tscn.

## Large text that lands over the wide shot. Leave empty for no title card.
@export var title := "PART TWO"
@export var subtitle := "NO TRACE OF LUCK"

## The atmosphere the burst leaves behind (an emitter name, as in atmosphere_<name>). The reveal
## clears whatever was drifting before it starts and brings this in as the frame breaks open, so
## the burst is the first time petals appear and not just more of them. Empty for none.
@export var atmosphere := "petals"

## Which of the picture's focus points to hold tight on before the frame opens. Empty uses
## the first one, and a picture with none is framed on its center.
@export var focusName := ""

## The music that arrives as the frame opens. There is no impact sound: the hit is this track's
## own first downbeat.
@export var music : AudioStream
## Seconds from the start of `music` to that downbeat. The track is started this long before
## the frame opens, so its pickup plays under the end of the build and the beat lands on the
## opening frame. Measure it per track; 0 starts the track exactly as the frame opens.
@export var musicDownbeat := 0.0
