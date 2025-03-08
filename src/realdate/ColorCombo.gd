extends Node
class_name ColorCombo

var topicText : String
var colors : Array[RealDateColorHelper.TopicColors] = []

func _init(txt: String, col: Array[RealDateColorHelper.TopicColors]):
    topicText = txt
    colors = col