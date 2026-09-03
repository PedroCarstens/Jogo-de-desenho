@tool
extends AnimatableBody2D
class_name MovingPlatform

#========== MOVIMENTO
@export_category("Movimento")
@export var velocidade: float = 80.0
@export var movimento_automatico: bool = true
@export var ping_pong: bool = true
@export var iniciar_no_inicio: bool = true

#========== TRAJETORIA
@export_category("Trajetoria")
@export var trajetoria: Curve2D = Curve2D.new():
	set(valor):
		trajetoria = valor
		atualizar_editor()

@export var fechar_trajetoria: bool = false:
	set(valor):
		fechar_trajetoria = valor
		atualizar_editor()

@export var mostrar_trajetoria: bool = true:
	set(valor):
		mostrar_trajetoria = valor
		atualizar_editor()

@export var mostrar_pontos: bool = true:
	set(valor):
		mostrar_pontos = valor
		atualizar_editor()

@export_range(8, 128, 1) var quantidade_pontos_editor: int = 48:
	set(valor):
		quantidade_pontos_editor = valor
		atualizar_editor()

#========== VISUAL
@export_category("Visual")
@export var tamanho: Vector2 = Vector2(96.0, 20.0):
	set(valor):
		tamanho = valor
		atualizar_visual()

#========== DEBUG / ESTADO
@export_category("Debug")
@export var mostrar_estado: bool = true

var progresso: float = 0.0
var direcao_movimento: float = 1.0
var pontos_trajetoria: PackedVector2Array = PackedVector2Array()

var _ultima_trajetoria: Curve2D
var _ultimo_tamanho: Vector2

func _ready() -> void:
	configurar_trajetoria_padrao()
	atualizar_visual()

	if Engine.is_editor_hint():
		atualizar_editor()
		return

	if iniciar_no_inicio:
		progresso = 0.0

	atualizar_posicao()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not movimento_automatico:
		return

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	var comprimento: float = max(trajetoria.get_baked_length(), 1.0)
	var delta_progresso: float = (velocidade * delta) / comprimento
	progresso += delta_progresso * direcao_movimento

	if ping_pong:
		if progresso >= 1.0:
			progresso = 1.0
			direcao_movimento = -1.0
		elif progresso <= 0.0:
			progresso = 0.0
			direcao_movimento = 1.0
	else:
		if progresso >= 1.0:
			progresso = 0.0
		elif progresso < 0.0:
			progresso = 1.0

	atualizar_posicao()


#========== CONFIGURACAO
func configurar_trajetoria_padrao() -> void:
	if trajetoria == null:
		trajetoria = Curve2D.new()

	if trajetoria.get_point_count() == 0:
		trajetoria.add_point(Vector2.ZERO)
		trajetoria.add_point(Vector2(0.0, 160.0))


func atualizar_posicao() -> void:
	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	var nova_posicao: Vector2 = trajetoria.sample_baked(
		progresso * trajetoria.get_baked_length(),
		fechar_trajetoria
	)

	global_position = nova_posicao


func atualizar_editor() -> void:
	if not Engine.is_editor_hint():
		return

	configurar_trajetoria_padrao()
	recalcular_pontos_trajetoria()
	queue_redraw()


func atualizar_visual() -> void:
	var colisao: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D

	if colisao != null:
		var forma: RectangleShape2D = colisao.shape as RectangleShape2D
		if forma == null:
			forma = RectangleShape2D.new()
			colisao.shape = forma
		forma.size = tamanho

	if visual != null:
		var metade: Vector2 = tamanho * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-metade.x, -metade.y),
			Vector2(metade.x, -metade.y),
			Vector2(metade.x, metade.y),
			Vector2(-metade.x, metade.y)
		])

	if Engine.is_editor_hint():
		atualizar_editor()


func recalcular_pontos_trajetoria() -> void:
	pontos_trajetoria.clear()

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	var comprimento: float = trajetoria.get_baked_length()
	if comprimento <= 0.0:
		return

	for i in range(quantidade_pontos_editor + 1):
		var distancia: float = comprimento * (float(i) / float(quantidade_pontos_editor))
		pontos_trajetoria.append(trajetoria.sample_baked(distancia, fechar_trajetoria))


#========== EDITOR / TRAJETORIA
func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if not mostrar_trajetoria:
		return

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	if pontos_trajetoria.is_empty():
		recalcular_pontos_trajetoria()

	for i in range(pontos_trajetoria.size() - 1):
		draw_line(
			pontos_trajetoria[i],
			pontos_trajetoria[i + 1],
			Color(1.0, 0.8, 0.15, 0.9),
			2.0,
			true
		)

	if fechar_trajetoria and pontos_trajetoria.size() > 1:
		draw_line(
			pontos_trajetoria[pontos_trajetoria.size() - 1],
			pontos_trajetoria[0],
			Color(1.0, 0.8, 0.15, 0.9),
			2.0,
			true
		)

	if mostrar_pontos:
		for ponto in pontos_trajetoria:
			draw_circle(ponto, 2.5, Color(1.0, 0.8, 0.15, 0.85))

		# Ponto inicial
		draw_circle(trajetoria.get_point_position(0), 5.0, Color(0.3, 1.0, 0.4, 1.0))

		# Ponto final
		draw_circle(
			trajetoria.get_point_position(trajetoria.get_point_count() - 1),
			5.0,
			Color(1.0, 0.3, 0.3, 1.0)
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if Engine.is_editor_hint():
			configurar_trajetoria_padrao()
			recalcular_pontos_trajetoria()


func _get_configuration_warnings() -> PackedStringArray:
	var avisos: PackedStringArray = PackedStringArray()

	if trajetoria == null or trajetoria.get_point_count() < 2:
		avisos.append("A trajetoria precisa de pelo menos 2 pontos.")

	if velocidade <= 0.0:
		avisos.append("A velocidade deve ser maior que 0.")

	return avisos
