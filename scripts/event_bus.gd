extends Node


signal try_catch(char_name)

signal bounce()

signal spawn_impy(spawn_location)
signal spawn_bunbun(spawn_location)

signal here_item(emitter, launch_vector) 
signal here_item_bunbun(emitter, launch_vector) #idk if this will give vector i want

signal spawn_ball(player_pos, scene_name, direction, vert_direction, facing)
signal reset_ball(spawn_location)
signal launch_ball(x, y)
signal target_break()
signal beat_level()
