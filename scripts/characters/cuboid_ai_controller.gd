extends AIController3D
class_name CuboidAIController

var cuboid : Cuboid


func init(player: Node3D):
	super.init(player)
	cuboid = player as Cuboid


func _process(delta: float) -> void:
	print(get_obs())


func get_obs() -> Dictionary:
	var dictionary : Dictionary
	
	dictionary["self"] = cuboid.get_observation_informations(cuboid)
	
	var i : int = 1
	for entity in EntityManager.instance.entity_list:
		if entity == cuboid:
			continue
		
		dictionary["entity_" + str(i)] = entity.get_observation_informations(cuboid)
	
	return dictionary
