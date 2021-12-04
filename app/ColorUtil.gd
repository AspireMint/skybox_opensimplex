extends Node

func from_value(value: float, colors: Array = ColorSet.GREYSCALE) -> Color:
	var float_index: float = range_lerp(value, 0, 1, 0, colors.size()-1)
	var index: int = int(floor(float_index))
	var ratio1: float = 1-(float_index - index)
	var ratio2: float = 1-ratio1
	
	if index == colors.size()-1:
		index -= 1
	
	var color1: Color = colors[index]
	var color2: Color = colors[index+1]
	
	var red = range_lerp(color1.r8*ratio1 + color2.r8*ratio2, 0, 255, 0, 1)
	var green = range_lerp(color1.g8*ratio1 + color2.g8*ratio2, 0, 255, 0, 1)
	var blue = range_lerp(color1.b8*ratio1 + color2.b8*ratio2, 0, 255, 0, 1)
	
	return Color(red, green, blue)

func by_alpha(alpha: float) -> Color:
	return Color(0, 0, 0, alpha)

func mix_colors(c1: Color, c2: Color) -> Color:
	return Color((c1.r+c2.r)/2, (c1.g+c2.g)/2, (c1.b+c2.b)/2)

func substract_color(c1: Color, c2: Color) -> Color:
	return Color(clamp(c1.r-c2.r, 0, 1), clamp(c1.g-c2.g, 0, 1), clamp(c1.b-c2.b, 0, 1))

func mask_color(c1: Color, c2: Color) -> Color:
	return Color(clamp(c1.r, 0, c2.r), clamp(c1.g, 0, c2.g), clamp(c1.b, 0, c2.b))
