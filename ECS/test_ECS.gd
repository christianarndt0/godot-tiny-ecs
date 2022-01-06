extends "res://addons/gut/test.gd"


func before_all():
	# Logger and ECS autoloads must exist in the node tree
	assert_not_null(get_node("/root/Logger"))
	assert_not_null(get_node("/root/ECS"))
	
	# change logger params
	Logger.set_level(0)
	Logger.set_log_dir("user://log_test_ecs.csv")
	
	
func before_each():
	# delete entities
	ECS.reset_entities()


func test_entities():
	Logger.info("test_entities()")
	var n_entities = 10
	
	# create some new entities without any components
	var new_entities = []
	for i in range(n_entities):
		# new_entity() returns newly generated id
		new_entities.append(ECS.new_entity([]))
	
	# an entity-compononent LUT maps the entity id to a bit vector encoding
	# which components this entity uses (fast bit-wise integer comparison
	# by systems which naively iterate over all entities (for starters))
	var entities = ECS.entities()  # list of UUIDs
	assert_eq(entities.size(), n_entities)
	for e in entities:
		assert_has(new_entities, e)
		
	# add components (with standard values) to an existing entity
	var id = entities[0]
	var comps = ["transform", "gravity"]
	var vec = ECS.comp2bin(comps)
	
	ECS.attach(id, comps)  # attach components by name
	
	assert_true(ECS.components_of(id) == vec)  # compare bit-wise match
	assert_true("transform" in ECS.get_entity(id).keys())
	assert_true("gravity" in ECS.get_entity(id).keys())
	
	# remove a component
	vec = ECS.comp2bin(["transform"])
	
	ECS.detach(id, ["gravity"])
	
	assert_true(ECS.components_of(id) == vec)
	assert_true("transform" in ECS.get_entity(id).keys())
	assert_true(not "gravity" in ECS.get_entity(id).keys())
		
	# delete an entity with a specific id and signal its deletion
	watch_signals(ECS)
	ECS.del_entity(new_entities[5])
	assert_true(not new_entities[5] in ECS.entities())
	assert_signal_emitted(ECS, "entity_deleted")
	

func test_components():
	Logger.info("test_components()")
	# look for json files in given directories
	var path = "res://ECS/components/"
	assert_property(ECS, "component_paths", [path], [path, path])
	
	# get list of components, no duplicates allowed, first come first serve
	var components = ECS.components()
	gut.p(ECS._component_list)
	gut.p(ECS._component_jsons)
	
	assert_typeof(components, TYPE_ARRAY)
	assert_eq(components.count("gravity"), 1)
	assert_eq(components.count("transform"), 1)
	assert_eq(components.count("velocity"), 1)


func test_system():
	Logger.info("test_system()")
	# one sample iteration of a hypothetical system transforming component data
	# of an entity
	var components = ECS.components()
	assert_true(components.size() >= 3)
	
	# create new entities (dict with id -> components)
	# components that don't exist will simply be ignored
	var id1 = ECS.new_entity(["transform", "thisdoesnotexist"])
	var id2 = ECS.new_entity(["transform", "gravity"])
	var id3 = ECS.new_entity(["velocity"])
	var id4 = ECS.new_entity(["transform", "hover"])
	var id5 = ECS.new_entity(["transform", "hover"])
	
	# generate bit-vector for component comparison
	var bin = ECS.comp2bin(["transform", "hover"])
	gut.p("ecs internal order: %s" % str(ECS._component_list))
	gut.p("bit vector (as int) for transform & hover: %s" % bin)
	
	# iterate over all entities and transform the appropriate ones
	var skipped = []
	var changed = []
	for e in ECS.entities():
		if not ECS.components_of(e) == bin:
			gut.p("Skipping %s" % e)
			skipped.append(e)
			continue
		
		gut.p("Change height to %s" % (changed.size() + 3))
		ECS.get_entity(e)["height"] = changed.size() + 3	
		changed.append(e)
		
	assert_eq(skipped.size(), 3)
	assert_eq(changed.size(), 2)
	
	for e in changed:
		gut.p("height = %s" % ECS.get_entity(e).get("height"))
		

func test_save_load():
	Logger.info("test_save_load()")
	# create new entities and modify their data
	var id1 = ECS.new_entity(["transform", "gravity"])
	var comp1 = ECS.comp2bin(["transform", "gravity"])
	var data1 = ECS.get_entity(id1)
	data1.transform.origin.x = 1.23
	data1.gravity.magnitude = 9001
	
	var id2 = ECS.new_entity(["transform", "velocity"])
	var comp2 = ECS.comp2bin(["transform", "velocity"])
	var data2 = ECS.get_entity(id2)
	data2.velocity.magnitude = 1.0
	
	# save entity data
	ECS.save_state("user://test_save.json")
	
	# load entity state (resets existing entities)
	ECS.load_state("user://test_save.json")
	var entities = ECS.entities()
	
	# check loaded data
	assert_has(entities, id1)
	assert_has(entities, id2)
	
	assert_true((ECS.components_of(id1) & comp1) == comp1)
	assert_true((ECS.components_of(id2) & comp2) == comp2)

	assert_almost_eq(ECS.get_entity(id1).transform.origin.x, 1.23, 0.01)
	assert_eq(ECS.get_entity(id1).gravity.magnitude, 9001, "gravity should be over 9000")
	assert_almost_eq(ECS.get_entity(id2).velocity.magnitude, 1.0, 0.001)
	
