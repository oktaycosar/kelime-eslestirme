extends HBoxContainer
## Eğlenceli, çözünürlükten bağımsız başlık: her harf küçük bir kelime kartıdır.

const TILE_SIZE := Vector2(31, 39)
const AMBER := Color(0.95, 0.62, 0.08, 1.0)
const AMBER_EDGE := Color(1.0, 0.82, 0.32, 1.0)
const NAVY := Color(0.08, 0.24, 0.46, 1.0)
const NAVY_EDGE := Color(0.25, 0.58, 0.92, 1.0)
const EMERALD := Color(0.04, 0.5, 0.36, 1.0)
const EMERALD_EDGE := Color(0.22, 0.86, 0.65, 1.0)


func _ready() -> void:
	if get_child_count() > 0:
		return
	_add_word("KELİME", AMBER, AMBER_EDGE)
	_add_connector()
	_add_word("EŞLEŞTİRME", EMERALD, EMERALD_EDGE)


func _add_word(value: String, accent: Color, accent_edge: Color) -> void:
	for index in value.length():
		var use_accent := index % 2 == 0
		_add_tile(value.substr(index, 1), accent if use_accent else NAVY, accent_edge if use_accent else NAVY_EDGE)


func _add_tile(letter: String, background: Color, edge: Color) -> void:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.01, 0.03, 0.08, 0.55)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	tile.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = letter
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 23)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.01, 0.03, 0.08, 0.75))
	label.add_theme_constant_override("shadow_offset_y", 2)
	tile.add_child(label)
	add_child(tile)


func _add_connector() -> void:
	var connector := Label.new()
	connector.custom_minimum_size = Vector2(48, 39)
	connector.text = "↔"
	connector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connector.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	connector.add_theme_font_size_override("font_size", 28)
	connector.add_theme_color_override("font_color", Color(0.58, 0.84, 1.0))
	connector.add_theme_color_override("font_shadow_color", Color(0.08, 0.42, 0.7, 0.65))
	connector.add_theme_constant_override("shadow_offset_y", 2)
	add_child(connector)
