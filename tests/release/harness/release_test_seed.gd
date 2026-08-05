class_name ReleaseTestSeed
extends RefCounted
## Test-only acceleration helpers. Never referenced by release UI or boot routes.


const TEST_SEED_TAG := &"release_test_seed"


func apply_headless_defaults() -> void:
	## Mute audio buses; headless already has no window focus.
	var bus_count: int = AudioServer.bus_count
	for i in range(bus_count):
		AudioServer.set_bus_mute(i, true)


func seed_economy(game: Node, money: float = 50000.0, popularity: float = 50.0, legend: float = 50.0, attention: float = 20.0) -> void:
	var economy: Node = game.get("economy")
	if economy == null:
		return
	economy.call("set_value", &"money", money)
	economy.call("set_value", &"popularity", popularity)
	economy.call("set_value", &"legend", legend)
	economy.call("set_value", &"attention", attention)
	economy.call("set_value", &"scandal", 0.0)


func ensure_attention(game: Node, amount: float = 10.0) -> void:
	var economy: Node = game.get("economy")
	if economy == null:
		return
	if float(economy.call("get_value", &"attention")) < amount:
		economy.call("set_value", &"attention", amount)


func bump_successful_dates(game: Node, target: int) -> void:
	## Test acceleration only: raise counter used by stage/worthiness gates.
	var cur: int = int(game.get("total_successful_dates"))
	if cur < target:
		game.set("total_successful_dates", target)


func advance_time_to(game: Node, day: int, minutes: int) -> void:
	var time_api: Node = game.get("time")
	if time_api == null:
		return
	time_api.call("skip_to_minutes", day, minutes)
