extends Node


signal ecs_log
signal entity_deleted


enum {DEBUG, INFO, WARNING, ERROR}


# ecs data
var _entities = {}  # entity id -> component dict
var _entity_component_lut = {}  # entity id -> int for bitwise comparisons
var _component_list = []  # ordered list of existing components
var _component_jsons = {}  # component name -> default json as string

# statistics (for uid generation)
onready var _t0 = OS.get_system_time_msecs()
var _entities_created = 0  # counter of created entities


# initialize ECS
func init(component_paths: Array):
	# load component templates from json files
	_load_json_components(component_paths)


# save all currently existing entities
func save_state(file_name: String) -> void:
	# create save data
	var save = JSON.print({"entities": _entities})
	
	# write to file
	var file = File.new()
	file.open(file_name, File.WRITE)
	file.store_string(save)
	file.close()
	
	emit_signal("ecs_log", INFO, "Game saved to %s" % file_name)
	

# restore entity states from file and re-create lut 
func load_state(file_name: String) -> void:
	# reset current state
	reset_entities()
	# load json save file
	var file = File.new()
	file.open(file_name, File.READ)
	var txt = file.get_as_text()
	file.close()
	
	# convert entity json to dictionary
	var res = JSON.parse(txt)
	if res.error == OK:
		# set entity data
		_entities = res.result.entities
		for id in entities():
			# set bits in the lut
			_entity_component_lut[id] = comp2bin(get_entity(id).keys())
		emit_signal("ecs_log", INFO, "Loaded save file from %s" % file_name)
	else:
		emit_signal("ecs_log", ERROR, "Save file parsing failed")


# convert an array of component names to a single integer bit vector that
# encodes the same information
func comp2bin(component_names: Array) -> int:
	# init bit vector with no bits set
	var bin = 0
	
	for cn in component_names:
		var index = _component_list.find(cn)
		if index >= 0:
			# set bit
			bin = bin | (1 << index)
		else:
			emit_signal("ecs_log", WARNING, "Component %s does not exist, ignoring it" % cn)
			
	emit_signal("ecs_log", DEBUG, "Components: %s -> int: %s" % [str(component_names), bin])
	return bin


# hard-reset all entities
func reset_entities():
	emit_signal("ecs_log", INFO, "Hard-resetting all entities")
	_entities = {}
	_entity_component_lut = {}
	

# remove an entity and its data completly
func del_entity(id: String) -> void:
	# remove entity id and lut entry
	var ret1 = _entities.erase(id)
	var ret2 = _entity_component_lut.erase(id)
	
	if ret1 and ret2:
		emit_signal("ecs_log", INFO, "Deleted entity %s" % id)
		emit_signal("entity_deleted", id)
	else:
		emit_signal("ecs_log", WARNING, "Trying to delete entity %s but it doesn't exist" % id)


# create a new entity with the given components and return the entitys id
func new_entity(component_names: Array) -> String:
	# generate new unique id for this entity
	var stamp = String(OS.get_unix_time())
	var rnd = String(hash([_t0, _entities_created]))
	var id = stamp + "-" + rnd
	_entities_created += 1
	
	# create new (empty) entry for the new entity
	_entities[id] = {}
	_entity_component_lut[id] = 0  # 0 -> no bit is set -> no components attached
	
	# attach components
	emit_signal("ecs_log", INFO, "Created entity %s" % id)
	attach(id, component_names)

	return id
	

# return a list of existing entities (ids)
func entities() -> Array:
	return _entities.keys()
	

# get the component dictionary of a specific entity
func get_entity(id: String) -> Dictionary:
	return _entities[id]
	

# attach a list of components to an entity	
func attach(id: String, component_names: Array) -> void:
	# instance components for the entity, overwrites existing components
	for cn in component_names:
		var index = _component_list.find(cn)
		if index >= 0:
			# copy default component
			_entities[id][cn] = _component_jsons[cn].duplicate(true)
			# set bit in the lut
			_entity_component_lut[id] |= 1 << index
			emit_signal("ecs_log", INFO, "Added component %s to %s" % [cn, id])
		else:
			emit_signal("ecs_log", WARNING, "Component %s does not exist, ignoring it" % cn)
	

# remove a list of components from an entity
func detach(id: String, component_names: Array) -> void:
	# instance components for the entity, overwrites existing components
	for cn in component_names:
		var index = _component_list.find(cn)
		if index >= 0:
			# remove component data from dictionary
			_entities[id].erase(cn)
			# clear bit in the lut
			_entity_component_lut[id] &= ~(1 << index)
			emit_signal("ecs_log", INFO, "Removed component %s from %s" % [cn, id])
		else:
			emit_signal("ecs_log", WARNING, "Entity %s doesn't have component %s" % [id, cn])
	

# get the bit vector encoding the entitys components
func components_of(id: String) -> int:
	return _entity_component_lut[id]
	
	
# return list of component names
func components() -> Array:
	return _component_jsons.keys()


func _load_json_components(component_paths: Array):
	# load json files as component templates from all given directories
	for cp in component_paths:
		emit_signal("ecs_log", INFO, "Load components from %s" % cp)
		# get file names in this path
		var files = []
		var dir = Directory.new()
		dir.open(cp)
		dir.list_dir_begin()
		
		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with("."):
				files.append(file)
			
		dir.list_dir_end()
		emit_signal("ecs_log", DEBUG, "Found %s" % str(files))
		
		# load json data
		for fname in files:
			var f = File.new()
			f.open(cp + fname, File.READ)
			var res = JSON.parse(f.get_as_text())
			
			if res.error == OK:
				# file content is a valid json -> add component
				var json = res.result
				var comp_name = fname.trim_suffix(".json")
				
				if not comp_name in _component_list:
					_component_list.append(comp_name)
					_component_jsons[comp_name] = json
			else:
				emit_signal("ecs_log", ERROR, "JSON parsing failed on %s%s" % [cp, fname])
	
	emit_signal("ecs_log", DEBUG, "new component list: %s" % str(_component_list))
