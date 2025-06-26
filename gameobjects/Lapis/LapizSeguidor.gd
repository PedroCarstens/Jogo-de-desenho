extends Node2D
# Este nó representa a "ponta" do lápis e segue o cursor

func _process(_delta):
	position = get_global_mouse_position()
	# Atualiza a posição para onde estiver o mouse (ou caneta)
