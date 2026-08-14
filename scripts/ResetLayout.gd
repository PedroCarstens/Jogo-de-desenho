extends Node

# Script responsável por reiniciar o layout da cena.


# ============================================================
# CONFIGURAÇÃO
# ============================================================

@export_category("Reiniciar Layout")

# Ação responsável por reiniciar a cena.
@export var acao_reiniciar: StringName = &"reiniciar_layout"


# ============================================================
# PROCESSAMENTO
# ============================================================

func _process(_delta: float) -> void:

	# Verifica se a tecla configurada foi pressionada.
	if Input.is_action_just_pressed(acao_reiniciar):

		# Reinicia a cena atual.
		get_tree().reload_current_scene()
