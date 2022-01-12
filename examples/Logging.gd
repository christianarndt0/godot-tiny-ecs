extends Node


func _ready():
	# connect ECS logger to custom callback
	ECS.connect("ecs_log", self, "_on_ecs_log")
	
	# create some entities
	ECS.new_entity([])
	ECS.new_entity(["gravity"])
	ECS.new_entity(["gravity", "velocity"])


func _on_ecs_log(level, msg):
	# print log messages
	if level == ECS.DEBUG:
		print(OS.get_unix_time(), ": DEBUG: ", msg)
	elif level == ECS.INFO:
		print(OS.get_unix_time(), ": INFO: ", msg)
	elif level == ECS.WARNING:
		print(OS.get_unix_time(), ": WARNING: ", msg)
	elif level == ECS.ERROR:
		print(OS.get_unix_time(), ": ERROR: ", msg)
