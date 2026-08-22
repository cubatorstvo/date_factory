class_name ProgressionRng
extends RefCounted

const STREAM_PROFILE: String = "PROFILE"
const STREAM_CAMPAIGN_INTEREST: String = "CAMPAIGN_INTEREST"
const STREAM_STAGE_PLAN_1: String = "STAGE_PLAN_1"
const STREAM_STAGE_PLAN_2: String = "STAGE_PLAN_2"
const STREAM_STAGE_PLAN_3: String = "STAGE_PLAN_3"
const STREAM_STAGE_PLAN_4: String = "STAGE_PLAN_4"
const STREAM_EXECUTION_1: String = "EXECUTION_1"
const STREAM_EXECUTION_2: String = "EXECUTION_2"
const STREAM_EXECUTION_3: String = "EXECUTION_3"
const STREAM_EXECUTION_4: String = "EXECUTION_4"
const STREAM_DATE: String = "DATE"


static func stage_plan_stream(stage: int) -> String:
	return "STAGE_PLAN_%d" % clampi(stage, 1, 4)


static func execution_stream(stage: int) -> String:
	return "EXECUTION_%d" % clampi(stage, 1, 4)


static func derive_seed(base_seed: int, stream_name: String) -> int:
	var input: String = "%s:%s" % [str(base_seed), stream_name]
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(input.to_utf8_buffer())
	var digest: PackedByteArray = ctx.finish()
	var value: int = 0
	for i in range(8):
		value = (value << 8) | int(digest[i])
	return value & 0x7FFFFFFFFFFFFFFF


static func make(base_seed: int, stream_name: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = derive_seed(base_seed, stream_name)
	return rng


static func sha256_hex(payload: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(payload.to_utf8_buffer())
	return ctx.finish().hex_encode()
