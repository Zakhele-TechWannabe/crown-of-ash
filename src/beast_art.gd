extends RefCounted
## Small cached ink silhouettes. Species keep their anatomy; cultivation changes tint rather than size.
const Palette = preload("res://src/palette.gd")
static var _textures: Dictionary = {}
static func texture(group: String, frame: int = 0) -> Texture2D:
	var key := group + str(frame)
	if _textures.has(key): return _textures[key]
	var image := Image.create(32,32,false,Image.FORMAT_RGBA8)
	var fur := Palette.EARTH.lightened(.25)
	if group in ["wolf","goat","sheep"]: fur = Palette.STONE
	if group in ["bear","boar","panda"]: fur = Palette.INK_SOFT
	if group in ["fox","tiger"]: fur = Palette.BRASS
	var small := group in ["hare","pheasant","chicken","porcupine"]
	var body := Rect2i(5,16 if small else 12,18,8 if small else 10)
	image.fill_rect(body.grow(1),Palette.OUTLINE)
	image.fill_rect(body,fur)
	image.fill_rect(Rect2i(7,body.position.y,12,2),fur.lightened(.2))
	for x in [8,20]:
		image.fill_rect(Rect2i(x+frame,22,3,6-frame),Palette.OUTLINE)
		image.fill_rect(Rect2i(x+frame,22,2,5-frame),fur)
	image.fill_rect(Rect2i(22,body.position.y-3,7,8),Palette.OUTLINE)
	image.fill_rect(Rect2i(23,body.position.y-2,5,6),fur)
	image.set_pixel(27,body.position.y-1,Palette.PAPER)
	if group in ["deer","goral","takin","cattle","goat"]:
		image.fill_rect(Rect2i(23,body.position.y-8,2,6),Palette.OUTLINE)
	if group in ["wolf", "fox"]:
		image.fill_rect(Rect2i(23,5,3,6),fur)
		image.fill_rect(Rect2i(1,14,7,3),fur)
	if group in ["bear", "panda"]:
		image.fill_rect(Rect2i(7,8,14,7),fur)
		image.fill_rect(Rect2i(24,6,4,5),fur)
	if group == "panda":
		image.fill_rect(Rect2i(10,11,9,10),Palette.PAPER)
		image.fill_rect(Rect2i(24,10,3,3),Palette.PAPER)
	if group == "takin":
		image.fill_rect(Rect2i(6,9,15,6),fur)
		image.fill_rect(Rect2i(25,4,5,2),Palette.OUTLINE)
	if group == "monkey":
		image.fill_rect(Rect2i(2,7,2,17),fur)
	if group == "leopard":
		for x in [9,14,19]: image.fill_rect(Rect2i(x,14,2,2),Palette.OUTLINE)
	if group == "hare": image.fill_rect(Rect2i(23,7,2,9),fur)
	if group in ["tiger","boar"]:
		for x in [9,14,19]: image.fill_rect(Rect2i(x,body.position.y,2,5),Palette.OUTLINE)
	if group in ["pheasant","chicken"]: image.fill_rect(Rect2i(5,17,7,2),Palette.GREEN)
	if group == "porcupine":
		for x in range(5,23,3): image.fill_rect(Rect2i(x,12,1,8),Palette.STONE)
	if group == "fox": image.fill_rect(Rect2i(1,17,7,5),Palette.BRASS)
	_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]
