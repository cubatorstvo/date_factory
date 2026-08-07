class_name MediaPublishResult
extends RefCounted
## Typed outcome of Media.publish_photo (MODULE 15).


var ok: bool = false
var error: MediaTypes.PublishError = MediaTypes.PublishError.OK
var photo_id: StringName = &""
var attention_gained: int = 0
var attention_after: int = 0
var new_offer_girl_ids: Array[StringName] = []
