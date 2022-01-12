extends Node


func _ready():
	# initialize ECS and load component templates
	ECS.init(["res://ECS/components/"])
	print("components: ", ECS.components())
	
	# create a new entity
	var entity: String = ECS.new_entity(["gravity"])
	print("new entity: ", entity)
	
	# create another new entity
	entity = ECS.new_entity([])
	print("new entity: ", entity)
	
	print_entities()
	
	# remove an entity
	ECS.del_entity(entity)

	# add components to an entity
	entity = ECS.entities()[0]
	ECS.attach(entity, ["gravity", "velocity"])
	
	print_entities()
	
	# remove components
	ECS.detach(entity, ["velocity"])
	
	print_entities()
	

func print_entities():
	# get list of all existing entities (id's)
	for e in ECS.entities():
		# print entity ids and their currently attached components
		print("components of ", e, ": ", ECS.components_of(e))  # bit vector
		print("get entity ", e, ": ", ECS.get_entity(e))  # dictionary
