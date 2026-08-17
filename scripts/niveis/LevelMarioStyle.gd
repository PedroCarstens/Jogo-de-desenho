extends Node2D
# Configuração específica de movimento para este nível.
#
# Os valores horizontais partem dos dados documentados do SMB1 NTSC:
# 24 subpixels/frame para a velocidade normal e 40 para a corrida.
# Considerando 16 subpixels = 1 pixel e 60 FPS, isso corresponde a
# 90 px/s e 150 px/s neste projeto.
#
# Este script NÃO altera o Player.gd.
# Ele aplica um preset somente ao Player desta cena.

@export_category("Movimento do Nível")

# Referência ao jogador desta fase.
@export var jogador: CharacterBody2D

# 24 subpixels/frame = 1.5 pixels/frame = 90 pixels/segundo.
@export var velocidade_normal: float = 90.0

# 40 subpixels/frame = 2.5 pixels/frame = 150 pixels/segundo.
@export var velocidade_correndo: float = 150.0

# Aceleração adaptada para a escala deste projeto.
@export var aceleracao: float = 720.0

# Desaceleração adaptada para a escala deste projeto.
@export var desaceleracao: float = 960.0

# Controle aéreo reduzido para preservar a sensação de inércia.
@export_range(0.0, 1.0, 0.01) var controle_no_ar: float = 0.65

# Impulso vertical do salto.
@export var impulso_pulo: float = -240.0

# Gravidade adaptada às unidades da Godot.
@export var gravidade: float = 720.0

# Força durante a subida.
@export_range(0.1, 2.0, 0.01) var gravidade_subindo: float = 1.0

# A queda utiliza força maior que a subida.
@export_range(0.1, 3.0, 0.01) var gravidade_caindo: float = 1.4

# Limite de queda adaptado para o projeto.
@export var velocidade_maxima_queda: float = 600.0


func _ready() -> void:
	# Aplica depois que todos os nós da fase terminaram de inicializar.
	# Isso garante que os valores padrão do Player não sobrescrevam
	# o preset específico desta fase.
	call_deferred("aplicar_preset")


func aplicar_preset() -> void:
	# Verifica se existe um jogador configurado.
	if jogador == null:
		push_warning("LevelMarioStyle: jogador não foi configurado.")
		return

	# Aplica os valores somente ao jogador desta fase.
	jogador.velocidade_normal = velocidade_normal
	jogador.velocidade_correndo = velocidade_correndo
	jogador.aceleracao = aceleracao
	jogador.desaceleracao = desaceleracao
	jogador.controle_no_ar = controle_no_ar
	jogador.impulso_pulo = impulso_pulo
	jogador.gravidade = gravidade
	jogador.gravidade_subindo = gravidade_subindo
	jogador.gravidade_caindo = gravidade_caindo
	jogador.velocidade_maxima_queda = velocidade_maxima_queda

	# Registra no console quais valores foram aplicados.
	print("Preset clássico aplicado ao Player:")
	print("Velocidade normal: ", jogador.velocidade_normal)
	print("Velocidade corrida: ", jogador.velocidade_correndo)
	print("Aceleração: ", jogador.aceleracao)
	print("Desaceleração: ", jogador.desaceleracao)
	print("Impulso pulo: ", jogador.impulso_pulo)
	print("Gravidade: ", jogador.gravidade)
