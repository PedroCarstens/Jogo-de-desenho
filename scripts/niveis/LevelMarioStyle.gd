extends Node2D
# Configuração específica de movimento para este nível.
# Os valores são uma aproximação em pixels/segundo da sensação
# clássica de plataforma 2D, adaptada para a escala deste projeto.
#
# O Player continua usando os mesmos parâmetros globais.
# Este script apenas sobrescreve os valores desta instância.

@export_category("Movimento do Nível")

# Referência ao jogador desta fase.
@export var jogador: CharacterBody2D

# Velocidade de caminhada inspirada no ritmo clássico.
@export var velocidade_normal: float = 168.0

# Velocidade de corrida inspirada no ritmo clássico.
@export var velocidade_correndo: float = 216.0

# Aceleração rápida para manter resposta imediata.
@export var aceleracao: float = 1100.0

# Desaceleração utilizada ao soltar o movimento.
@export var desaceleracao: float = 1400.0

# Controle aéreo reduzido para preservar o estilo clássico.
@export_range(0.0, 1.0, 0.01) var controle_no_ar: float = 0.65

# Impulso vertical do salto.
@export var impulso_pulo: float = -390.0

# Gravidade do nível.
@export var gravidade: float = 1050.0

# Gravidade durante a subida.
@export var gravidade_subindo: float = 0.92

# Gravidade durante a queda.
@export var gravidade_caindo: float = 1.08

# Limite de queda.
@export var velocidade_maxima_queda: float = 900.0


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
