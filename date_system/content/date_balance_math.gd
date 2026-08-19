class_name DateBalanceMath
extends RefCounted


static func combinations(n: int, k: int) -> float:
	if k < 0 or n < 0 or k > n:
		return 0.0
	if k == 0 or k == n:
		return 1.0
	var choose: int = mini(k, n - k)
	var result: float = 1.0
	for i in range(1, choose + 1):
		result = result * float(n - choose + i) / float(i)
	return result


static func at_least_one_positive_probability(total_tags: int, positive_count: int, draws: int) -> float:
	if draws <= 0 or total_tags <= 0:
		return 0.0
	var positives: int = clampi(positive_count, 0, total_tags)
	var take: int = mini(draws, total_tags)
	if positives <= 0:
		return 0.0
	var negatives: int = total_tags - positives
	if negatives < take:
		return 1.0
	var total_combinations: float = combinations(total_tags, take)
	if total_combinations <= 0.0:
		return 0.0
	return 1.0 - combinations(negatives, take) / total_combinations


static func format_percent(value: float) -> String:
	return "%.1f%%" % (value * 100.0)
