class_name ContentValidationIssue
extends RefCounted

var severity: DateTypes.ValidationSeverity = DateTypes.ValidationSeverity.ERROR
var code: String = ""
var resource_type: String = ""
var resource_id: String = ""
var field: String = ""
var message: String = ""


func to_dictionary() -> Dictionary:
	return {
		"severity": "ERROR" if severity == DateTypes.ValidationSeverity.ERROR else "WARNING",
		"code": code,
		"resource_type": resource_type,
		"resource_id": resource_id,
		"field": field,
		"message": message,
	}
