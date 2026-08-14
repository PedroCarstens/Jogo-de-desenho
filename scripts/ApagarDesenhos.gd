extends Button

# Script responsável por apagar todos os desenhos criados
# pelo DesenhoController.


# ============================================================
# CONFIGURAÇÃO
# ============================================================

@export_category("Desenhos")

# Referência ao DesenhoController.
#
# Arraste o nó DesenhoController da cena para este campo
# no Inspector.
@export var desenho_controller: Node


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:

	# Conecta o botão ao próprio script.
	#
	# Dessa maneira não precisamos configurar manualmente
	# o sinal pressed() pelo editor.
	pressed.connect(apagar_desenhos)


# ============================================================
# APAGAR DESENHOS
# ============================================================

func apagar_desenhos() -> void:

	# Verifica se o DesenhoController foi configurado.
	if desenho_controller == null:

		push_warning(
			"DesenhoController não foi configurado no botão."
		)

		return


	# Verifica se o objeto possui a função responsável
	# por apagar os desenhos.
	if desenho_controller.has_method("apagar_todos_desenhos"):

		# Solicita ao DesenhoController que apague
		# todos os desenhos.
		desenho_controller.apagar_todos_desenhos()

	else:

		push_warning(
			"O DesenhoController não possui "
			+ "apagar_todos_desenhos()."
		)
