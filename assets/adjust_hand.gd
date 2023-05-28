extends Spatial

export (NodePath) var left_hand_wrist
export (NodePath) var right_hand_wrist
export (NodePath) var left_arm_ik
export (NodePath) var right_arm_ik

onready var left_hand_wrist_node = get_node(left_hand_wrist)
onready var right_hand_wrist_node = get_node(right_hand_wrist)
onready var left_arm_ik_node = get_node(left_arm_ik)
onready var right_arm_ik_node = get_node(right_arm_ik)

var left_hand_transform = Transform(Basis.IDENTITY, Vector3(-1, -0.2, -2.8))
var right_hand_transform = Transform(Basis.IDENTITY, Vector3(1, -0.2, -2.8))


func _correct_finger_bone(bones: Array):
	var bones_rest = []
	var bones_pose = []
	for i in range(4):
		bones_rest.append($Skeleton.get_bone_rest(bones[i]))
		bones_pose.append($Skeleton.get_bone_pose(bones[i]))
	
	# correct the origin from root to tip
	for i in range(1, 4):
		var origin_p = bones_rest[i].origin
		var origin_p_n = origin_p.normalized()
		var origin_c = bones_rest[i].origin + bones_pose[i].origin
		var origin_c_n = origin_c.normalized()
		var rad = acos(origin_p_n.dot(origin_c_n))
		var norm = origin_p_n.cross(origin_c_n).normalized()
		if norm.length() < 0.1:
			continue
			
		var corr = Basis(norm, rad)
		
		# correct origin
		bones_pose[i].origin = origin_p * (origin_c.length() / origin_p.length() - 1)
		# realign direction of children
		bones_pose[i].basis = corr.inverse() * bones_pose[i].basis
		# realign direction of self
		bones_pose[i - 1].basis = bones_pose[i - 1].basis * corr
	
	for i in range(4):
		#print(bones_pose[i])
		$Skeleton.set_bone_pose(bones[i], bones_pose[i])


func _correct_wrist_trans(hand: int, children: Array):
	var bones_rest = []
	var bones_pose = []
	for i in range(5):
		bones_rest.append($Skeleton.get_bone_rest(children[i]))
		bones_pose.append($Skeleton.get_bone_pose(children[i]))
	
	# calc the average angle and norm
	var rads = []
	var norms = []
	for i in range(5):
		var origin_p_n = bones_rest[i].origin.normalized()
		var origin_c_n = (bones_rest[i].origin + bones_pose[i].origin).normalized()
		var rad = acos(origin_p_n.dot(origin_c_n))
		var norm = origin_p_n.cross(origin_c_n).normalized()
		if norm.length() < 0.1:
			continue
		rads.append(rad)
		norms.append(norm)
	
	if rads.size() == 0:
		return
	var rad_avg = 0
	var norm_avg = Vector3(0, 0, 0)
	for i in range(rads.size()):
		rad_avg += rads[i]
		norm_avg += norms[i]
	rad_avg /= rads.size()
	norm_avg /= norms.size()
	norm_avg = norm_avg.normalized()
	
	var corr = Basis(norm_avg, rad_avg)
	
	for i in range(5):
		var origin_p = bones_rest[i].origin
		var origin_c = bones_rest[i].origin + bones_pose[i].origin
		# correct origin
		bones_pose[i].origin = origin_p * (origin_c.length() / origin_p.length() - 1)
		# realign direction of children
		bones_pose[i].basis = corr.inverse() * bones_pose[i].basis
		$Skeleton.set_bone_pose(children[i], bones_pose[i])
	
	var root_pose = $Skeleton.get_bone_pose(hand)
	root_pose.basis = root_pose.basis * corr
	$Skeleton.set_bone_pose(hand, root_pose)


func _update_ik():
	# record the transform of hands, and set previous transform when not tracked.
	if left_hand_wrist_node.is_active():
		left_hand_transform = left_hand_wrist_node.get_global_transform()
	if right_hand_wrist_node.is_active():
		right_hand_transform = right_hand_wrist_node.get_global_transform()
	
	left_arm_ik_node.set_target_transform(left_hand_transform)
	right_arm_ik_node.set_target_transform(right_hand_transform)


func _distort_hand():
	# to test without binding to openxr hand
	var t = Transform.IDENTITY
	t.origin = Vector3(0.03, 0, 0)
	$Skeleton.set_bone_pose(40, t)
	t.origin = Vector3(0.03, 0, 0)
	$Skeleton.set_bone_pose(41, t)
	t.origin = Vector3(0.02, 0, 0)
	$Skeleton.set_bone_pose(42, t)
	t.origin = Vector3(0.01, 0, 0)
	$Skeleton.set_bone_pose(43, t)


func _process(delta):
#	_distort_hand()

	_correct_finger_bone([56, 57, 58, 59])
	_correct_finger_bone([40, 41, 42, 43])
	_correct_finger_bone([44, 45, 46, 47])
	_correct_finger_bone([52, 53, 54, 55])
	_correct_finger_bone([48, 49, 50, 51])

	_correct_finger_bone([122, 123, 124, 125])
	_correct_finger_bone([106, 107, 108, 109])
	_correct_finger_bone([110, 111, 112, 113])
	_correct_finger_bone([118, 119, 120, 121])
	_correct_finger_bone([114, 115, 116, 117])

	_correct_wrist_trans(39, [56, 40, 44, 52, 48])
	_correct_wrist_trans(105, [122, 106, 110, 118, 114])
	
	_update_ik()
	
