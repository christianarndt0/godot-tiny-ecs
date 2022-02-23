extends Node


var _vecs = []
var _timers = []
var _n = 0


func _ready():
	# deactivate system
	set_process(false)
	
	# get number of subsystems
	_n = get_child_count()

	# connect ECS signals
	assert(ECS.connect("ecs_ready", self, "_on_ecs_ready") == OK)
	

func _on_ecs_ready():
	# initialize timers
	for i in range(_n):
		_timers.append(get_child(i).period)
		
	# initialize component vectors
	for i in range(_n):
		_vecs.append(ECS.comp2bin(get_child(i).components))
	
	# activate system
	set_process(true)


func _process(delta):
	# subsystem not ready or offline: -1, subsystem ready: time delta since last call
	var deltas = []
	
	for i in range(_n):
		# update timers
		_timers[i] -= delta
		if _timers[i] < 0:
			# timers is ready
			var p = get_child(i).period
			if p < 0:
				# period < 0 turns the subsystem off
				deltas.append(-1)
			else:
				# calculate actual subsystem delta
				deltas.append(p - _timers[i])
			# reset timer
			_timers[i] = p
		else:
			# subsystem is not ready yet
			deltas.append(-1)
	
	# for every entity
	for e in ECS.entities():
		# run every subsystem
		for i in range(_n):
			# when it's ready
			if deltas[i] < 0:
				continue
				
			# get subsystem node	
			var c = get_child(i)
			
			# run subsystem on entity if components match
			if ECS.cmatch(e, _vecs[i]):
				c.run(e, deltas[i])
