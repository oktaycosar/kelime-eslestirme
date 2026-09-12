extends SceneTree
##
## Headless test koşucusu.
##
## TestRunner.gd autoload olarak tasarlanmış bir Node; bu sarmalayıcı onu
## root'a ekleyip testleri çalıştırır ve sonucu exit code olarak döndürür.
##
## Kullanım:
##   godot --headless --path <proje> --script res://tests/run_tests.gd

func _init() -> void:
	call_deferred("_start")


func _start() -> void:
	var script: GDScript = load("res://tests/TestRunner.gd")
	if script == null:
		printerr("run_tests: TestRunner.gd yüklenemedi")
		quit(1)
		return
	var runner: Node = script.new()
	runner.name = "TestRunnerHost"
	root.add_child(runner)