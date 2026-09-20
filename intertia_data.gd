class_name InertiaData

var mass:float
var moment:float #About its center of mass, not about shape origin
var center_of_mass:Vector2 #Offset from physicsShape transform




func valid():
	if mass <= .00001: return false
	if moment <= .00001: return false
	return true
