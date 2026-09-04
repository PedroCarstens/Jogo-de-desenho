@tool
extends AnimatableBody2D
class_name MovingPlatform

#========== MOVIMENTO
@export_category("Movimento")
@export var duracao: float = 2.0
@export var movimento_automatico: bool = true
@export var ping_pong: bool = true
@export var iniciar_no_inicio: bool = true

# Compatibilidade com o sistema antigo baseado em velocidade.
# Para a atividade, deixe "usar_duracao" ligado.
@export var usar_duracao: bool = true
@export var velocidade: float = 80.0

#========== INTERPOLACAO
@export_category("Interpolacao")
@export_enum("Linear", "Ease In", "Ease Out", "Ease In-Out") var tipo_interpolacao: int = 0

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
var tempo_movimento: float = 0.0
var pontos_trajetoria: PackedVector2Array = PackedVector2Array()

# A plataforma e colocada no level design usando uma posicao global.
# A Curve2D e local ao prefab, entao guardamos essa posicao como origem.
var origem_global: Vector2 = Vector2.ZERO

# Assinatura usada para detectar alteracoes nas alcas/pontos da Curve2D.
var _ultima_assinatura_trajetoria: String = ""


func _ready() -> void:
	configurar_trajetoria_padrao()
	atualizar_visual()

	if Engine.is_editor_hint():
		atualizar_editor()
		return

	# A posicao escolhida pelo designer vira A, a origem da plataforma.
	origem_global = global_position

	if iniciar_no_inicio:
		progresso = 0.0
		tempo_movimento = 0.0

	atualizar_posicao()


func _process(_delta: float) -> void:
	# @tool permite atualizar a pre-visualizacao sem apertar Play.
	if Engine.is_editor_hint():
		verificar_alteracoes_editor()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not movimento_automatico:
		return

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	#========== T NORMALIZADO
	# t e o progresso matematico da interpolacao:
	# 0 representa A e 1 representa B.
	if usar_duracao:
		var tempo_total: float = max(duracao, 0.001)
		tempo_movimento += delta * direcao_movimento
		progresso = clamp(tempo_movimento / tempo_total, 0.0, 1.0)
	else:
		# Modo legado: velocidade em pixels por segundo pela distancia da curva.
		var comprimento: float = max(trajetoria.get_baked_length(), 1.0)
		progresso += ((velocidade * delta) / comprimento) * direcao_movimento

	#========== LIMITES
	if progresso >= 1.0:
		progresso = 1.0
		if ping_pong:
			direcao_movimento = -1.0
		else:
			progresso = 0.0
	elif progresso <= 0.0:
		progresso = 0.0
		if ping_pong:
			direcao_movimento = 1.0
		else:
			progresso = 0.0

	if usar_duracao:
		tempo_movimento = progresso * max(duracao, 0.001)

	atualizar_posicao()


#========== FUNCOES DE INTERPOLACAO
func calcular_t_interpolado(t: float) -> float:
	# Primeiro garantimos que t fique entre 0 e 1.
	t = clamp(t, 0.0, 1.0)

	match tipo_interpolacao:
		0: # LINEAR
			# A velocidade de A ate B permanece constante.
			return t

		1: # EASE IN
			# Comeca devagar e acelera ate B.
			return t * t

		2: # EASE OUT
			# Comeca rapido e desacelera perto de B.
			return 1.0 - pow(1.0 - t, 2.0)

		3: # EASE IN-OUT
			# Junta Ease In na primeira metade e Ease Out na segunda.
			if t < 0.5:
				return 2.0 * t * t
			return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0

	return t


func atualizar_posicao() -> void:
	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	# O t normalizado passa pela funcao escolhida.
	# Isso altera o QUANTO avancamos na curva em cada instante.
	var t_interpolado: float = calcular_t_interpolado(progresso)

	# sample_baked usa distancia sobre a Curve2D.
	# Como a distancia vai de 0 ate o comprimento total,
	# o mesmo caminho pode ser percorrido com quatro velocidades diferentes.
	var comprimento: float = trajetoria.get_baked_length()
	var distancia: float = t_interpolado * comprimento
	var deslocamento_curva: Vector2 = trajetoria.sample_baked(distancia, fechar_trajetoria)

	# Soma o deslocamento local a origem escolhida no Level Design.
	global_position = origem_global + deslocamento_curva


#========== EDITOR
func atualizar_editor() -> void:
	if not Engine.is_editor_hint():
		return

	configurar_trajetoria_padrao()
	recalcular_pontos_trajetoria()
	atualizar_assinatura_trajetoria()
	queue_redraw()


func verificar_alteracoes_editor() -> void:
	if trajetoria == null:
		return

	var assinatura_atual: String = criar_assinatura_trajetoria()

	if assinatura_atual != _ultima_assinatura_trajetoria:
		recalcular_pontos_trajetoria()
		_ultima_assinatura_trajetoria = assinatura_atual
		queue_redraw()


func criar_assinatura_trajetoria() -> String:
	if trajetoria == null:
		return "null"

	var assinatura: String = str(trajetoria.get_point_count())

	for i in range(trajetoria.get_point_count()):
		assinatura += "|" + str(trajetoria.get_point_position(i))
		assinatura += "|" + str(trajetoria.get_point_in(i))
		assinatura += "|" + str(trajetoria.get_point_out(i))

	return assinatura


func atualizar_assinatura_trajetoria() -> void:
	_ultima_assinatura_trajetoria = criar_assinatura_trajetoria()


#========== VISUAL DA PLATAFORMA
func atualizar_visual() -> void:
	var colisao: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D

	if colisao != null:
		var forma: RectangleShape2D = colisao.shape as RectangleShape2D
		if forma == null:
			forma = RectangleShape2D.new()
			colisao.shape = forma
		forma.size = tamanho
		colisao.position = Vector2.ZERO

	if visual != null:
		var metade: Vector2 = tamanho * 0.5
		visual.position = Vector2.ZERO
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

	var quantidade: int = max(quantidade_pontos_editor, 1)

	for i in range(quantidade + 1):
		var distancia: float = comprimento * (float(i) / float(quantidade))
		pontos_trajetoria.append(trajetoria.sample_baked(distancia, fechar_trajetoria))


#========== DESENHO DA TRAJETORIA NO EDITOR
func _draw() -> void:
	if not Engine.is_editor_hint() or not mostrar_trajetoria:
		return

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	if pontos_trajetoria.is_empty():
		recalcular_pontos_trajetoria()

	# A linha mostra a geometria da Curve2D.
	# A interpolacao nao altera o caminho, apenas a velocidade durante o Play.
	for i in range(pontos_trajetoria.size() - 1):
		draw_line(pontos_trajetoria[i], pontos_trajetoria[i + 1], Color(1.0, 0.8, 0.15, 0.9), 2.0, true)

	if fechar_trajetoria and pontos_trajetoria.size() > 1:
		draw_line(pontos_trajetoria[-1], pontos_trajetoria[0], Color(1.0, 0.8, 0.15, 0.9), 2.0, true)

	if mostrar_pontos:
		for ponto in pontos_trajetoria:
			draw_circle(ponto, 2.5, Color(1.0, 0.8, 0.15, 0.85))

		# A = inicio
		draw_circle(trajetoria.get_point_position(0), 5.0, Color(0.3, 1.0, 0.4, 1.0))

		# B = final
		draw_circle(trajetoria.get_point_position(trajetoria.get_point_count() - 1), 5.0, Color(1.0, 0.3, 0.3, 1.0))


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE and Engine.is_editor_hint():
		configurar_trajetoria_padrao()
		recalcular_pontos_trajetoria()
		atualizar_assinatura_trajetoria()


func _get_configuration_warnings() -> PackedStringArray:
	var avisos: PackedStringArray = PackedStringArray()

	if trajetoria == null or trajetoria.get_point_count() < 2:
		avisos.append("A trajetoria precisa de pelo menos 2 pontos.")

	if usar_duracao and duracao <= 0.0:
		avisos.append("A duracao deve ser maior que 0.")

	if not usar_duracao and velocidade <= 0.0:
		avisos.append("A velocidade deve ser maior que 0.")

	return avisos
