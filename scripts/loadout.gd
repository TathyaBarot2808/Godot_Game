extends Node
class_name LoadoutManager


var loadout: Dictionary={
	0: "dash",
	1: "recoil",
	2: "",
}


var active_slot: int=0
signal loadout_changed #loadout changed


func set_active_slot(index: int) -> void:
	if not _is_valid_slot(index):
		return
	active_slot=index
	loadout_changed.emit()
	


func get_active_ability() -> String:
	return loadout[active_slot]
	
func equip(ability_name:String , slot_index:int) ->void:
	if not _is_valid_slot(slot_index):
		return
	
	var manager:= _get_abilities_manager()
	if not manager:
		return
	if not manager.is_unlocked(ability_name):
		push_error("LoadoutManager: ability not unlocked -> " + ability_name)
		return
	loadout[slot_index] = ability_name
	loadout_changed.emit()



func unequip(slot_index: int) -> void:
	if not _is_valid_slot(slot_index):
		return
	loadout[slot_index] = ""
	loadout_changed.emit()
	
	
func get_available_abilities() -> Array[String]:
	var manager := _get_abilities_manager()
	if not manager:
		return []
	return manager.get_unlocked_abilities()
	


func _is_valid_slot(index: int) -> bool:
	if index not in loadout:
		push_error("LoadoutManager: invalid slot -> " + str(index))
		return false
	return true

func _get_abilities_manager() -> AbilitiesManager:
	var parent := get_parent()
	if not parent is AbilitiesManager:
		push_error("LoadoutManager: parent must be AbilitiesManager")
		return null
	return parent as AbilitiesManager
	
	
	
	
