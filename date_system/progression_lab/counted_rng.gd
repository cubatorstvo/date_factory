class_name CountedRng
extends RandomNumberGenerator

var stream_name: String = ""
var draw_count: int = 0


@warning_ignore("NATIVE_METHOD_OVERRIDE")
func randf() -> float:
	draw_count += 1
	return super.randf()


@warning_ignore("NATIVE_METHOD_OVERRIDE")
func randi() -> int:
	draw_count += 1
	return super.randi()


@warning_ignore("NATIVE_METHOD_OVERRIDE")
func randf_range(from: float, to: float) -> float:
	draw_count += 1
	return super.randf_range(from, to)


@warning_ignore("NATIVE_METHOD_OVERRIDE")
func randi_range(from: int, to: int) -> int:
	draw_count += 1
	return super.randi_range(from, to)