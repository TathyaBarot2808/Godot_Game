extends Node2D


@export_group("Mana Settings") #Groups the variables under a collapsible header
@export var max_mana: float = 100.0
@export var regen_rate: float = 20.0       # mana per second
@export var regen_delay: float = 2.0       # seconds after spending before regen starts
@export var shoot_cost: float = 25.0  
@export var dash_cost: float = 40.0  
@export var vdash_cost: float=30.0


signal mana_changed(current: float, max: float) 
#Whenever mana changes, this fires and passes the new current and max values to whoever is listening (the HUD)
	

var current_mana: float
var regen_timer: float = 0.0

func _ready() -> void:
	current_mana = max_mana


func _process(delta: float) -> void:
	if regen_timer > 0:
		regen_timer -= delta
		return
	if current_mana < max_mana: #Checked every frame	
		current_mana = minf(current_mana + regen_rate * delta, max_mana) #Rewriting the value of mana and making sure it doesnt overflow
		mana_changed.emit(current_mana, max_mana) #Calling the mana change signal every frame



func can_spend(amount: float) -> bool:
	return current_mana >= amount

func spend(amount: float) -> void:
	current_mana = maxf(current_mana - amount, 0.0)
	regen_timer = regen_delay #Regenration delay so it can only regenrate after the last attack
	mana_changed.emit(current_mana, max_mana)

func restore(amount: float) -> void:
	current_mana = minf(current_mana + amount, max_mana)
	mana_changed.emit(current_mana, max_mana)
