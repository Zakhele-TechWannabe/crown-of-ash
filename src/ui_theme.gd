extends RefCounted
## The one Theme. Every panel, button, bar and label takes its look from here; nothing else sets fonts or sizes.
## Fonts: one heading face (serif) and one body face. Sizes: Palette.SMALL, BODY, TITLE, HEAD.
## Buttons: one flat box in four variations. Button (brass, an action), Tab, Chip (a filter or small fact) and Card (a clickable tile).
const Palette = preload("res://src/palette.gd")
const SPACE_8 := 8
const SPACE_12 := 12
const SPACE_16 := 16
const SPACE_24 := 24
static var _theme: Theme
static var _heading: Font
static var _body: Font


static func heading() -> Font:
	if _heading == null:
		_heading = load("res://assets/fonts/NotoSerifDisplay-Bold.ttf")
	return _heading


static func body() -> Font:
	if _body == null:
		var variation := FontVariation.new()
		variation.base_font = load("res://assets/fonts/Lato-Bold.ttf")
		variation.opentype_features = {"tnum": 1}
		_body = variation
	return _body


## The one box shape: flat fill, thin border, small radius.
static func box(fill: Color, border: Color = Palette.LINE, width: int = 1, margin_x: int = 10, margin_y: int = 5, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	style.anti_aliasing = false
	return style


static func _button(theme: Theme, type: String, fills: Array, text: Color, margin_x: int = 10, margin_y: int = 5, border: Color = Palette.LINE) -> void:
	# fills: normal, hover, pressed.
	theme.set_stylebox("normal", type, box(fills[0], border, 1, margin_x, margin_y))
	theme.set_stylebox("hover", type, box(fills[1], Palette.INK_SOFT, 1, margin_x, margin_y))
	theme.set_stylebox("pressed", type, box(fills[2], Palette.INK_SOFT, 1, margin_x, margin_y))
	theme.set_stylebox("hover_pressed", type, box(fills[2], Palette.INK_SOFT, 1, margin_x, margin_y))
	theme.set_stylebox("disabled", type, box(Palette.PAPER_DARK.lerp(Palette.PAPER, 0.5), Palette.LINE, 1, margin_x, margin_y))
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	for state: String in ["font_color", "font_hover_color", "font_focus_color"]:
		theme.set_color(state, type, text)
	theme.set_color("font_disabled_color", type, Palette.INK_SOFT)
	theme.set_font_size("font_size", type, Palette.BODY)


static func build() -> Theme:
	if _theme != null:
		return _theme
	var theme := Theme.new()
	theme.default_font = body()
	theme.default_font_size = Palette.BODY
	for container: String in ["HBoxContainer", "VBoxContainer", "HFlowContainer"]:
		theme.set_constant("separation", container, 8)
	theme.set_constant("h_separation", "HFlowContainer", SPACE_8)
	theme.set_constant("v_separation", "HFlowContainer", SPACE_8)
	theme.set_constant("h_separation", "GridContainer", 8)
	theme.set_constant("v_separation", "GridContainer", 8)

	# Text.
	theme.set_color("font_color", "Label", Palette.INK)
	for pair: Array in [["Heading", Palette.HEAD], ["Title", Palette.TITLE]]:
		theme.set_type_variation(pair[0], "Label")
		theme.set_font("font", pair[0], heading())
		theme.set_font_size("font_size", pair[0], pair[1])
		theme.set_color("font_color", pair[0], Palette.INK)
	theme.set_type_variation("Small", "Label")
	theme.set_font_size("font_size", "Small", Palette.SMALL)
	theme.set_color("font_color", "Small", Palette.INK_SOFT)

	# Panels: the page, a card on the page, the top bar and a small tag.
	theme.set_stylebox("panel", "PanelContainer", box(Palette.PAPER, Palette.LINE, 1, SPACE_16, SPACE_16, 6))
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", box(Palette.PAPER_LIGHT, Palette.LINE, 0, SPACE_16, SPACE_12))
	theme.set_type_variation("Bar", "PanelContainer")
	var bar := box(Palette.PAPER, Palette.LINE, 0, 12, 5, 0)
	bar.border_width_bottom = 2
	theme.set_stylebox("panel", "Bar", bar)
	theme.set_type_variation("Tag", "PanelContainer")
	theme.set_stylebox("panel", "Tag", box(Palette.PAPER_LIGHT, Palette.LINE, 1, 7, 1, 3))

	# Buttons.
	var brass := Palette.BRASS.darkened(0.22)
	_button(theme, "Button", [brass, Palette.BRASS.darkened(0.12), Palette.BRASS.darkened(0.38)], Palette.PAPER_LIGHT, 10, 5, Palette.INK_SOFT)
	theme.set_color("font_pressed_color", "Button", Palette.PAPER_LIGHT)
	theme.set_color("font_hover_pressed_color", "Button", Palette.PAPER_LIGHT)
	theme.set_color("icon_normal_color", "Button", Palette.PAPER_LIGHT)
	theme.set_type_variation("Tab", "Button")
	_button(theme, "Tab", [Palette.PAPER_DARK, Palette.PAPER_LIGHT, Palette.PAPER_LIGHT], Palette.INK, 12, 6)
	var active := box(Palette.PAPER_LIGHT, Palette.INK_SOFT, 1, 12, 6)
	active.border_width_bottom = 3
	active.border_color = Palette.GOLD.darkened(0.15)
	theme.set_stylebox("pressed", "Tab", active)
	theme.set_stylebox("hover_pressed", "Tab", active)
	theme.set_type_variation("Chip", "Button")
	_button(theme, "Chip", [Palette.PAPER_DARK, Palette.PAPER_LIGHT, Palette.GOLD.lerp(Palette.PAPER, 0.35)], Palette.INK, 9, 2)
	theme.set_font_size("font_size", "Chip", Palette.SMALL)
	theme.set_type_variation("Hot", "Chip")
	_button(theme, "Hot", [Palette.RED.lerp(Palette.PAPER_LIGHT, 0.72), Palette.RED.lerp(Palette.PAPER_LIGHT, 0.6), Palette.RED.lerp(Palette.PAPER_LIGHT, 0.5)], Palette.RED.darkened(0.35), 9, 2, Palette.RED)
	theme.set_font_size("font_size", "Hot", Palette.SMALL)
	theme.set_type_variation("Card", "Button")
	_button(theme, "Card", [Palette.PAPER_LIGHT, Palette.PAPER_LIGHT.lightened(0.35), Palette.PAPER_DARK], Palette.INK, 10, 8)
	for type: String in ["Tab", "Chip", "Hot", "Card"]:
		theme.set_color("font_pressed_color", type, theme.get_color("font_color", type))
		theme.set_color("font_hover_pressed_color", type, theme.get_color("font_color", type))
		theme.set_color("icon_normal_color", type, Palette.INK)

	# Pickers and fields.
	_button(theme, "OptionButton", [Palette.PAPER_LIGHT, Palette.PAPER_LIGHT.lightened(0.35), Palette.PAPER_DARK], Palette.INK, 10, 5)
	theme.set_color("font_pressed_color", "OptionButton", Palette.INK)
	theme.set_color("font_hover_pressed_color", "OptionButton", Palette.INK)
	theme.set_color("modulate_arrow", "OptionButton", Palette.INK)
	theme.set_stylebox("panel", "PopupMenu", box(Palette.PAPER_LIGHT, Palette.INK_SOFT, 1, 6, 6))
	theme.set_stylebox("hover", "PopupMenu", box(Palette.PAPER_DARK, Palette.PAPER_DARK, 0, 6, 2))
	for state: String in ["font_color", "font_hover_color"]:
		theme.set_color(state, "PopupMenu", Palette.INK)
	theme.set_font_size("font_size", "PopupMenu", Palette.BODY)
	theme.set_stylebox("normal", "LineEdit", box(Palette.PAPER_LIGHT, Palette.LINE, 1, 10, 5))
	theme.set_stylebox("focus", "LineEdit", box(Palette.PAPER_LIGHT, Palette.INK_SOFT, 1, 10, 5))
	theme.set_color("font_color", "LineEdit", Palette.INK)
	theme.set_color("font_placeholder_color", "LineEdit", Palette.INK_SOFT)
	theme.set_color("caret_color", "LineEdit", Palette.INK)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, "CheckBox", Palette.INK)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())

	# Tables, bars and rules.
	theme.set_stylebox("panel", "Tree", box(Palette.PAPER_LIGHT, Palette.LINE, 1, 6, 4))
	theme.set_stylebox("focus", "Tree", StyleBoxEmpty.new())
	theme.set_stylebox("selected", "Tree", box(Palette.PAPER_DARK, Palette.PAPER_DARK, 0, 0, 0, 0))
	theme.set_stylebox("selected_focus", "Tree", box(Palette.PAPER_DARK, Palette.PAPER_DARK, 0, 0, 0, 0))
	for state: String in ["title_button_normal", "title_button_hover", "title_button_pressed"]:
		theme.set_stylebox(state, "Tree", box(Palette.PAPER_DARK, Palette.LINE, 0, 6, 3, 0))
	for state: String in ["font_color", "font_selected_color", "font_hovered_color", "title_button_color"]:
		theme.set_color(state, "Tree", Palette.INK)
	theme.set_color("guide_color", "Tree", Color(Palette.LINE, 0.35))
	theme.set_color("relationship_line_color", "Tree", Palette.LINE)
	theme.set_font_size("font_size", "Tree", Palette.BODY)
	theme.set_font_size("title_button_font_size", "Tree", Palette.BODY)
	theme.set_stylebox("background", "ProgressBar", box(Palette.PAPER_DARK, Palette.PAPER_DARK, 0, 0, 0, 2))
	theme.set_stylebox("fill", "ProgressBar", box(Palette.BRASS, Palette.BRASS, 0, 0, 0, 2))
	theme.set_color("font_color", "ProgressBar", Palette.INK)
	var rule := StyleBoxLine.new()
	rule.color = Palette.LINE
	theme.set_stylebox("separator", "HSeparator", rule)
	for scroll: String in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", scroll, box(Color(Palette.PAPER_DARK, 0.6), Palette.PAPER_DARK, 0, 4, 4, 4))
		for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
			theme.set_stylebox(state, scroll, box(Palette.BRASS if state == "grabber" else Palette.BRASS.darkened(0.2), Palette.BRASS, 0, 4, 4, 4))

	# Tooltips are small cards.
	theme.set_stylebox("panel", "TooltipPanel", box(Palette.PAPER_LIGHT, Palette.INK_SOFT, 1, 10, 6))
	theme.set_font("font", "TooltipLabel", body())
	theme.set_font_size("font_size", "TooltipLabel", Palette.SMALL)
	theme.set_color("font_color", "TooltipLabel", Palette.INK)
	_theme = theme
	return theme


## A thin meter in one signal colour, for skills, feelings and progress.
static func thin(bar: ProgressBar, colour: Color = Palette.GREEN, height: int = 6) -> void:
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	bar.add_theme_stylebox_override("background", box(Palette.PAPER_DARK, Palette.PAPER_DARK, 0, 0, 0, 2))
	bar.add_theme_stylebox_override("fill", box(colour, colour, 0, 0, 0, 2))


## A small parchment tag holding a few words: traits, bonds, map names.
static func tag(parent: Node, words: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Tag"
	var label := Label.new()
	label.text = words
	label.theme_type_variation = "Small"
	label.add_theme_color_override("font_color", Palette.INK)
	panel.add_child(label)
	parent.add_child(panel)
	return panel
