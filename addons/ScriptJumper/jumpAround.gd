@tool
extends EditorPlugin


const SAVE_FILE_NAME = "scriptJumper.cfg"

var scriptEditor : ScriptEditor

var jumpShortcutList:Array 
var assignScriptList:Array 
var scriptList : Array

var cycleNext : InputEventKey
var cyclePrevious : InputEventKey
var showScriptList : InputEventKey

var defaultKeyList = [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9,KEY_0]

var editor_setting : EditorSettings

var currentProjectName

var currentScriptIndex = 0

var settings :Dictionary = {
	"scriptJumper/jumpShortcutList": []
	,"scriptJumper/assignScriptList": []
	,"scriptJumper/cycleNext": _createNewShortcut(KEY_E)
	,"scriptJumper/cyclePrevious": _createNewShortcut(KEY_Q)
	,"scriptJumper/showAssignedList": _createNewShortcut(KEY_W)
	
}


func _enter_tree():
	currentProjectName = ProjectSettings.get_setting("application/config/name")
	#print(currentProjectName)
	cyclePrevious = InputEventKey.new()
	cyclePrevious.keycode = KEY_Q
	cyclePrevious.alt_pressed = true
	
	cycleNext = InputEventKey.new()
	cycleNext.keycode = KEY_E
	cycleNext.alt_pressed = true
	
	showScriptList = InputEventKey.new()
	showScriptList.keycode = KEY_S
	showScriptList.alt_pressed = true
	
	
	
	_createJumpKeys()
	_createAssignKeys()
	for i in defaultKeyList:
		var newScript = null
		scriptList.append(newScript)
	
	
	scriptEditor = EditorInterface.get_script_editor()
	set_editor_settings()
	pass


func _exit_tree():
	var config = ConfigFile.new()
	var path: String = EditorInterface.get_editor_paths().get_config_dir()
	path += "/"+SAVE_FILE_NAME
	config.load(path)
	
	for i in settings.keys():
		var val = editor_setting.get_setting(i)
		config.set_value("setting", i, val)
		editor_setting.erase(i)
	
	for i in scriptList.size():
		
		if scriptList[i] is Script:
			scriptList[i] = scriptList[i].get_script_property_list()[0].hint_string
			#print("Convert to string ",i)
	config.set_value(currentProjectName,"scriptList",scriptList)
	
	
	#for saving scriptlist on individual file
	#var saveProjectScripList = ConfigFile.new()
	#saveProjectScripList.set_value("projectScriptList","scriptList",scriptList)
	#saveProjectScripList.save(EditorInterface.get_editor_paths().get_config_dir()+"/"+currentProjectName+"_JumpList.cfg")
	#print("Project save ", EditorInterface.get_editor_paths().get_config_dir()+"/"+currentProjectName+"_JumpList.cfg")
	config.save(path)
	pass

#DETECT SHORTCUTS
func _shortcut_input(event) -> void:
	if !event.is_pressed() or event.is_echo():return
	
	if event.is_match(cycleNext):
		_cycleScripts(true)
	if event.is_match(cyclePrevious):
		_cycleScripts(false)
	if event.is_match(showScriptList):
		_printAssignedScripts()
		
	
	var shortcutIdx = 0
	for i in jumpShortcutList:
		if event.is_match(i):
			get_viewport().set_input_as_handled()
			if scriptList[shortcutIdx] != null:
				currentScriptIndex = shortcutIdx
				EditorInterface.edit_script(scriptList[currentScriptIndex])
			return
		shortcutIdx += 1
	
	shortcutIdx = 0
	for i in assignScriptList:
		if event.is_match(i):
			get_viewport().set_input_as_handled()
			scriptList[shortcutIdx] = scriptEditor.get_current_script()
			#print(scriptEditor.get_current_script().get_script_property_list()[0])
			return
		shortcutIdx += 1
		

func set_editor_settings() -> void:
	editor_setting = EditorInterface.get_editor_settings()
	var config = ConfigFile.new()
	var path: String = EditorInterface.get_editor_paths().get_config_dir()
	path += "/"+SAVE_FILE_NAME
	var err: Error = config.load(path)
	var projectJumpList = ConfigFile.new()
	var scriptListExist : Error = projectJumpList.load(EditorInterface.get_editor_paths().get_config_dir()+"/"+currentProjectName+"_JumpList.cfg")
	
	
	for i in settings.keys():
		var val
		if err == OK: 
			#print("save exist")
			val = config.get_value("setting", i, settings[i])
		else:
			val = settings[i]
		editor_setting.set_setting(i, val)
		editor_setting.set_initial_value(i, settings[i], false)

	if err == OK:
		scriptList = config.get_value(currentProjectName,"scriptList",scriptList)
		for i in scriptList.size():
			if scriptList[i] != null || typeof(scriptList[i]) != 0:
				#print(typeof(i))
				#print(scriptList[i])
				scriptList[i] = load(scriptList[i])
	
	editor_setting.set_setting("scriptJumper/scriptList",scriptList)
	editor_setting.set_initial_value("scriptJumper/scriptList",scriptList, false)
	
	jumpShortcutList = editor_setting.get_setting("scriptJumper/jumpShortcutList")
	assignScriptList= editor_setting.get_setting("scriptJumper/assignScriptList")
	scriptList= editor_setting.get_setting("scriptJumper/scriptList")
	cycleNext = editor_setting.get_setting("scriptJumper/cycleNext")
	cyclePrevious = editor_setting.get_setting("scriptJumper/cyclePrevious")
	showScriptList = editor_setting.get_setting("scriptJumper/showAssignedList")

func _createJumpKeys():
	settings["scriptJumper/jumpShortcutList"].clear()
	for i in defaultKeyList:
		var newKey: InputEventKey = InputEventKey.new()
		newKey.pressed = true
		newKey.keycode = i
		newKey.alt_pressed = true
		settings["scriptJumper/jumpShortcutList"].append(newKey)

func _createAssignKeys():
	settings["scriptJumper/assignScriptList"].clear()
	for i in defaultKeyList:
		var newKey: InputEventKey = InputEventKey.new()
		newKey.pressed = true
		newKey.keycode = i
		newKey.alt_pressed = true
		newKey.ctrl_pressed = true
		settings["scriptJumper/assignScriptList"].append(newKey)

func _cycleScripts(isNext:bool = true):
	get_viewport().set_input_as_handled()
	for i in scriptList:
		if isNext:
			currentScriptIndex += 1
			if currentScriptIndex >= scriptList.size(): currentScriptIndex=0
		else:
			currentScriptIndex -= 1
			if currentScriptIndex < 0: currentScriptIndex=scriptList.size()-1
		
		if scriptList[currentScriptIndex] != null:
			EditorInterface.edit_script(scriptList[currentScriptIndex])
			return

func _printAssignedScripts() -> void:
	get_viewport().set_input_as_handled()
	var x = 1
	#print(currentScriptIndex)
	print_rich("[center]=============----------> ASSIGNED SCRIPT JUMPER LIST <----------=============")
	for i in scriptList:
		
		if i == null:
			print_rich("[center][color=KHAKI] [%s] Empty Slot" % [x])
		else:
			var facePrint = "[center] [color=MEDIUM_TURQUOISE]"
			var tailPrint = ""
			if currentScriptIndex == x-1:
				facePrint = "[center] [color=DEEP_SKY_BLUE] ====> "
				tailPrint = " <===="
			print_rich(facePrint,"[%s] " % [x],i.get_script_property_list()[0].hint_string,tailPrint)
		x += 1


func _createNewShortcut(keyName:Key = KEY_E):
	var newShortcut = InputEventKey.new()
	newShortcut.keycode = keyName
	newShortcut.alt_pressed = true
	return newShortcut
