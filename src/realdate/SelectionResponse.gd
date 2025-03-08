extends Control

func setPrefersVariant(preferred: RealDateColorHelper.TopicColors, notPreferred: Array):
	%PrefersVariant.show()
	%NoneVariant.hide()

	%Preferred.texture = RealDateColorHelper.getColorCircleTextureForColor(preferred)

	for i in range(notPreferred.size()):
		var color = notPreferred[i]
		var trect = TextureRect.new()
		trect.texture = RealDateColorHelper.getColorCircleTextureForColor(color)
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		trect.custom_minimum_size.x = 40
		%PreferredContainer.add_child(trect)

func setNoneVariant(notPreferred: Array):
	%PrefersVariant.hide()
	%NoneVariant.show()

	for i in range(notPreferred.size()):
		var color = notPreferred[i]
		var trect = TextureRect.new()
		trect.texture = RealDateColorHelper.getColorCircleTextureForColor(color)
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		trect.custom_minimum_size.x = 40
		%NotPreferredContainer.add_child(trect)
