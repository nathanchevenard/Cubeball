extends Resource
class_name ONNXModel

var inferencer = null

## Action keys returned by the model (sorted alphabetically, matching the ONNX export order)
var action_keys: Array[String] = []

# Must provide the path to the model and the batch size
func _init(model_path, onnx_inference_script_path, batch_size):
	inferencer = load(onnx_inference_script_path).new()
	action_keys = inferencer.Initialize(model_path, batch_size)

# Takes the flat observation array, returns a dict keyed by action name.
# Values are float arrays — discrete actions still need int(round(...)) at call site.
func run_inference(obs: Array) -> Dictionary:
	if inferencer == null:
		printerr("Inferencer not initialized")
		return {}
	return inferencer.RunInference(obs)


func run_inference_with_state(obs: Array, state_h: Array, state_c: Array) -> Dictionary:
	if inferencer == null:
		printerr("Inferencer not initialized")
		return {}
	return inferencer.RunInferenceWithState(obs, state_h, state_c)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		inferencer.FreeDisposables()
		inferencer.free()
