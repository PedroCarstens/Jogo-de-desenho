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
# Para a atividade, use a duracao e deixe usar_duracao ligado.
@export var usar_duracao: bool = true
@export var velocidade: float = 80.0

#========== INTERPOLACAO
@export_category("Interpolacao")
@export_enum("Linear", "Ease In", "Ease Out", "Ease In-Out") var tipo_interpolacao: int = 0

#========== TRAJETORIA
@export_category("Trajetoria")
@export var trajetoria: Curve2D = Curve2D.new()
@export var mostrar_trajetoria: bool = true
@export var mostrar_pontos: bool = true
@export var mostrar_tempos: bool = true
@export_range(8, 128, 1) var quantidade_pontos_editor: int = 48

# Conecta visualmente B com A. A curva continua sendo editada normalmente.
@export var fechar_trajetoria: bool = false

#========== VISUAL
@export_category("Visual")
@export var tamanho: Vector2 = Vector2(96.0, 20.0)

#========== ESTADO
var progresso: float = 0.0
var direcao_movimento: float = 1.0
var tempo_movimento: float = 0.0

# Pontos usados somente para desenhar a pre-visualizacao no editor.
var pontos_trajetoria: PackedVector2Array = PackedVector2Array()
var pontos_interpolados: PackedVector2Array = PackedVector2Array()

# A posicao escolhida pelo designer no Level Design vira o ponto A.
var origem_global: Vector2 = Vector2.ZERO

# Assinatura usada para perceber mudancas feitas diretamente na Curve2D.
var _ultima_assinatura_editor: String = ""


func _ready() -> void:
	configurar_trajetoria_padrao()
	atualizar_visual()

	if Engine.is_editor_hint():
		atualizar_previsualizacao()
		return

	# A plataforma comeca exatamente onde foi colocada na cena.
	origem_global = global_position

	if iniciar_no_inicio:
		progresso = 0.0
		tempo_movimento = 0.0
		direcao_movimento = 1.0

	atualizar_posicao()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	# A Curve2D pode ser alterada arrastando os pontos e as alcas.
	# Por isso verificamos sua assinatura para atualizar a pre-visualizacao.
	verificar_alteracoes_editor()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not movimento_automatico:
		return

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	#========== T NORMALIZADO
	# t sempre representa o progresso entre A e B.
	# t = 0 -> A
	# t = 1 -> B
	if usar_duracao:
		var tempo_total: float = max(duracao, 0.001)
		tempo_movimento += delta * direcao_movimento
		progresso = clamp(tempo_movimento / tempo_total, 0.0, 1.0)
	else:
		# Modo antigo: velocidade em pixels por segundo.
		var comprimento: float = max(trajetoria.get_baked_length(), 1.0)
		progresso += (velocidade * delta / comprimento) * direcao_movimento

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
	# O valor recebido e normalizado para garantir 0 <= t <= 1.
	t = clamp(t, 0.0, 1.0)

	match tipo_interpolacao:
		0: # LINEAR
			return t

		1: # EASE IN
			# Comeca devagar e acelera.
			return t * t

		2: # EASE OUT
			# Comeca rapido e desacelera.
			return 1.0 - pow(1.0 - t, 2.0)

		3: # EASE IN-OUT
			# Ease In na primeira metade e Ease Out na segunda.
			if t < 0.5:
				return 2.0 * t * t
			return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0

	return t


func atualizar_posicao() -> void:
	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	# Primeiro calculamos o t alterado pela funcao de interpolacao.
	var t_interpolado: float = calcular_t_interpolado(progresso)

	# Depois transformamos esse t em distancia real sobre a Curve2D.
	var comprimento: float = trajetoria.get_baked_length()
	var distancia: float = t_interpolado * comprimento
	var deslocamento_curva: Vector2 = trajetoria.sample_baked(distancia, true)

	# A curva e local ao prefab. Somamos a origem colocada pelo designer.
	global_position = origem_global + deslocamento_curva


#========== EDITOR
func atualizar_previsualizacao() -> void:
	if not Engine.is_editor_hint():
		return

	configurar_trajetoria_padrao()
	recalcular_pontos_trajetoria()
	recalcular_pontos_interpolados()
	_ultima_assinatura_editor = criar_assinatura_editor()
	queue_redraw()


func verificar_alteracoes_editor() -> void:
	if trajetoria == null:
		return

	var assinatura_atual: String = criar_assinatura_editor()

	if assinatura_atual != _ultima_assinatura_editor:
		recalcular_pontos_trajetoria()
		recalcular_pontos_interpolados()
		_ultima_assinatura_editor = assinatura_atual
		queue_redraw()


func criar_assinatura_editor() -> String:
	if trajetoria == null:
		return "null"

	var assinatura: String = str(trajetoria.get_point_count())
	assinatura += "|tipo=" + str(tipo_interpolacao)
	assinatura += "|duracao=" + str(duracao)
	assinatura += "|fechada=" + str(fechar_trajetoria)
	assinatura += "|quantidade=" + str(quantidade_pontos_editor)

	for i in range(trajetoria.get_point_count()):
		assinatura += "|p=" + str(trajetoria.get_point_position(i))
		assinatura += "|in=" + str(trajetoria.get_point_in(i))
		assinatura += "|out=" + str(trajetoria.get_point_out(i))

	return assinatura


#========== CURVA
func configurar_trajetoria_padrao() -> void:
	if trajetoria == null:
		trajetoria = Curve2D.new()

	if trajetoria.get_point_count() == 0:
		trajetoria.add_point(Vector2.ZERO)
		trajetoria.add_point(Vector2(0.0, 180.0))


func recalcular_pontos_trajetoria() -> void:
	pontos_trajetoria.clear()

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	var comprimento: float = trajetoria.get_baked_length()
	if comprimento <= 0.0:
		return

	var quantidade: int = max(quantidade_pontos_editor, 1)

	for i in range(quantidade + 1):
		var t: float = float(i) / float(quantidade)
		var distancia: float = comprimento * t
		pontos_trajetoria.append(trajetoria.sample_baked(distancia, true))

	if fechar_trajetoria and pontos_trajetoria.size() > 1:
		pontos_trajetoria.append(pontos_trajetoria[0])


func recalcular_pontos_interpolados() -> void:
	pontos_interpolados.clear()

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	var comprimento: float = trajetoria.get_baked_length()
	if comprimento <= 0.0:
		return

	var quantidade: int = max(quantidade_pontos_editor, 1)

	for i in range(quantidade + 1):
		var t: float = float(i) / float(quantidade)
		var t_interpolado: float = calcular_t_interpolado(t)
		var distancia: float = comprimento * t_interpolado
		pontos_interpolados.append(trajetoria.sample_baked(distancia, true))


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


#========== DESENHO DO EDITOR
func _draw() -> void:
	if not Engine.is_editor_hint() or not mostrar_trajetoria:
		return

	if trajetoria == null or trajetoria.get_point_count() < 2:
		return

	if pontos_trajetoria.is_empty():
		recalcular_pontos_trajetoria()

	# Linha amarela = caminho geometrico da Curve2D.
	if pontos_trajetoria.size() >= 2:
		draw_polyline(
			pontos_trajetoria,
			Color(1.0, 0.8, 0.15, 0.9),
			2.0,
			true
		)

	# Marcadores = resposta temporal da interpolacao.
	# O caminho nao muda quando trocamos Linear/Ease.
	# O que muda e a distribuicao desses marcadores ao longo dele.
	if mostrar_tempos:
		if pontos_interpolados.is_empty():
			recalcular_pontos_interpolados()

		for i in range(pontos_interpolados.size()):
			var raio: float = 3.0
			if i == 0 or i == pontos_interpolados.size() - 1:
				raio = 5.0
			draw_circle(pontos_interpolados[i], raio, Color(0.25, 0.85, 1.0, 0.9))

	if mostrar_pontos:
		for ponto in pontos_trajetoria:
			draw_circle(ponto, 2.0, Color(1.0, 0.8, 0.15, 0.7))

		# A = inicio
		draw_circle(trajetoria.get_point_position(0), 6.0, Color(0.3, 1.0, 0.4, 1.0))

		# B = final
		draw_circle(
			trajetoria.get_point_position(trajetoria.get_point_count() - 1),
			6.0,
			Color(1.0, 0.3, 0.3, 1.0)
		)


func _get_configuration_warnings() -> PackedStringArray:
	var avisos: PackedStringArray = PackedStringArray()

	if trajetoria == null or trajetoria.get_point_count() < 2:
		avisos.append("A trajetoria precisa de pelo menos 2 pontos.")

	if duracao <= 0.0:
		avisos.append("A duracao deve ser maior que 0.")

	return avisos
