class_name UiNumberFormat
extends RefCounted
## Shared presentation number formatting (MODULE 22). No gameplay formulas.


static func format_grouped(value: int) -> String:
	var n: int = value
	var sign_prefix: String = ""
	if n < 0:
		sign_prefix = "-"
		n = -n
	var digits: String = str(n)
	var out: String = ""
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = " " + out
		out = digits[i] + out
		count += 1
	return sign_prefix + out


static func format_compact(value: int) -> String:
	var n: int = value
	var sign_prefix: String = ""
	if n < 0:
		sign_prefix = "-"
		n = -n
	if n < 10000:
		return sign_prefix + format_grouped(n)
	if n < 1_000_000:
		return sign_prefix + _format_scaled(float(n) / 1000.0, "K")
	if n < 1_000_000_000:
		return sign_prefix + _format_scaled(float(n) / 1_000_000.0, "M")
	return sign_prefix + _format_scaled(float(n) / 1_000_000_000.0, "B")


static func format_money(value: int) -> String:
	return "$ %s" % format_compact(value)


static func format_signed(value: int) -> String:
	if value > 0:
		return "+%d" % value
	if value < 0:
		return "%d" % value
	return "0"


static func format_rate(value: float, max_decimals: int = 2) -> String:
	if not is_finite(value):
		return "0"
	var decimals: int = maxi(0, max_decimals)
	var rounded: float = snappedf(value, pow(10.0, -float(decimals)))
	if is_equal_approx(rounded, roundf(rounded)):
		return str(int(roundf(rounded)))
	var text: String = ("%%.%df" % decimals) % rounded
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text


static func _format_scaled(scaled: float, suffix: String) -> String:
	var text: String = "%.2f" % scaled
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text + suffix
