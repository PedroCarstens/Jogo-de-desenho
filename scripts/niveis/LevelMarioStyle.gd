extends Node2D
# Configuração específica de movimento para este nível.
#
# Os valores horizontais partem dos dados documentados do SMB1 NTSC:
# 24 subpixels/frame para a velocidade normal e 40 para a corrida.
# Considerando 16 subpixels = 1 pixel e 60 FPS, isso corresponde a
# 90 px/s e 150 px/s neste projeto.
#
# A física vertical é adaptada para as unidades da Godot. Assim,
# preservamos a proporção de subida/queda sem alterar as mecânicas
# do Player.

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

# O salto original começa com aproximadamente -4 px/frame.
# Convertido para 60 FPS: -240 px/s.
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

	# Verifica se existe um jogador configurado.
	if jogador == null:
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
