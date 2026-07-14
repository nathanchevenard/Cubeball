extends Node
class_name Utilities


static func list_to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array && value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	
	push_warning("list_to_vector3 value is not a Vector3 or an Array of size 3")
	return Vector3(NAN, NAN, NAN)
