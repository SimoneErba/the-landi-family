extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 root.size = Vector2i(1920,1080)
 var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
 root.add_child(screen)
 screen.find_child("StartStrangerPortraitTest", true, false).pressed.emit()
 var grid = screen.content_overlay.find_child("StrangerPortraitGrid", true, false)
 assert(grid.get_child_count() == 100)
 var signatures := {}
 var bases := {}
 for card in grid.get_children():
  var id = card.name.trim_prefix("StrangerPortrait_")
  var person = screen.people[id]
  assert(person.parent_ids.is_empty())
  assert(person.spouse_id.is_empty())
  assert(person.branch_id == person.id)
  assert(not person.in_household)
  assert(person.age == 23)
  signatures[JSON.stringify(person.portrait.genetics)] = true
  bases[person.portrait.appearance["base_face"]] = true
  var restored = load("res://Simulation/PortraitIdentity.gd").new(person.id, person.portrait.to_data())
  assert(restored.to_data() == person.portrait.to_data(), "Illustrated portrait identity survives save restoration")
  var independently_generated = load("res://Simulation/PortraitIdentity.gd").new(person.id, {"appearance": {"presentation": person.portrait.appearance["presentation"]}})
  assert(person.portrait.to_data() == independently_generated.to_data(), "Same unparented generation as unrelated arrivals")
 assert(signatures.size() == 100)
 assert(bases.size() >= 12, "Strangers sample the expanded illustrated library")
 assert(screen.game_clock.state.head_id == "Giovanni")
 await process_frame
 await process_frame
 assert(not screen.focus_overlay.visible)
 var first = grid.get_child(0).get_child(0).get_child(0)
 var second = grid.get_child(1).get_child(0).get_child(0)
 assert(first.material != second.material)
 var count = screen.people.size()
 load("res://Scripts/StrangerPortraitPreview.gd").start(screen)
 assert(screen.people.size() == count, "Reopening does not duplicate strangers")
 screen.free()
 print("PASS: 100 unique independent identities, unrelated people, same ages and clickable gallery; bases used: ", bases.size())
 quit()
