extends RefCounted
class_name ChoiceScript

static func getChoicesForDialogueKey(dialogueKey: String) -> Dictionary[String, String]:
    assert(false, "implement getChoicesForDialogueKey")
    return {}

# Optional: how much the player has already seen of the choices getChoicesForDialogueKey just
# returned for this key, for the menu to show beside them (src/choice_display_button.gd).
#   choice key -> { "seen": how much of what is behind the choice has been seen,
#                   "total": how much there is (what is counted is up to the scene: the versions
#                            of a scene, the endings a route leads to...),
#                   "new": whether the scene it plays now is still unseen }
# A choice left out gets no mark, and a menu with no marks keeps its choices side by side.
# Main asks right after getChoicesForDialogueKey, each time a menu comes up: this must only
# answer, and change nothing.
static func getChoiceMarks(_dialogueKey: String) -> Dictionary:
    return {}
