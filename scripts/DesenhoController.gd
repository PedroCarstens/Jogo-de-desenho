extends Node2D
# Script responsável por desenhar traços com colisão física usando Line2D


#========== VARIÁVEIS ==========

@onready var lapiz: Node2D = $"../LapizSeguidor"
# Referência ao objeto do lápis que segue o mouse.

var desenhando := false
# Indica se o jogador está desenhando no momento.

var linha: Line2D
# Linha visual que representa o traço desenhado.

var corpo: StaticBody2D
# Corpo físico onde será adicionada a colisão.

var pontos: Array = []
# Lista de pontos globais do traço atual.

var elementos_desenhados: Array = []
# Armazena as linhas e colisores para apagar ou editar depois.


#====================================


#========== ENTRADA DE EVENTOS ==========

func _input(event):
	# Detecta cliques e movimentação do mouse para iniciar
	# ou continuar o traço.

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		if event.pressed:

			iniciar_linha()

		else:

			finalizar_linha()


	elif event is InputEventMouseMotion and desenhando and linha:

		var pos: Vector2 = lapiz.global_position

		if pontos.is_empty() or pos.distance_to(pontos[-1]) > 4.0:

			pontos.append(pos)
			linha.add_point(pos)


#====================================


#========== INICIAR NOVO TRAÇO ==========

func iniciar_linha():
	# Cria uma nova linha visual e prepara um corpo físico.

	linha = Line2D.new()

	linha.default_color = Color.WHITE
	linha.width = 6.0

	# round_precision utiliza valor inteiro.
	linha.round_precision = 1

	linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
	linha.end_cap_mode = Line2D.LINE_CAP_ROUND


	var inicio: Vector2 = lapiz.global_position

	linha.add_point(inicio)
	linha.add_point(inicio)
	# Dupla inicial evita "piscada" na linha.


	add_child(linha)


	corpo = StaticBody2D.new()

	add_child(corpo)


	pontos = [inicio]

	desenhando = true


#====================================


#========== FINALIZAR TRAÇO E GERAR COLISÃO ==========

func finalizar_linha():
	# Conclui o traço visual e gera a colisão física.

	if linha and pontos.size() >= 2:

		var origem: Vector2 = pontos[0]

		var pontos_locais: Array = []


		for p in pontos:

			pontos_locais.append(
				p - origem
			)
			# Converte pontos globais em locais.


		var colisao := CollisionPolygon2D.new()

		colisao.polygon = gerar_poligono(
			pontos_locais,
			linha.width
		)


		corpo.position = origem

		corpo.add_child(colisao)


		elementos_desenhados.append(linha)
		elementos_desenhados.append(corpo)


	else:

		# Remove traço inválido.

		if linha:

			linha.queue_free()

		if corpo:

			corpo.queue_free()


	linha = null
	corpo = null
	desenhando = false


#====================================


#========== GERAR POLÍGONO DE COLISÃO ==========

func gerar_poligono(
	pontos_base: Array,
	largura: float
) -> PackedVector2Array:

	# Gera um contorno ao redor da linha com base
	# nos pontos e largura.


	var metade: float = largura * 0.5

	var esquerda: Array = []
	var direita: Array = []


	for i in pontos_base.size():

		var normal: Vector2 = Vector2.UP


		if i < pontos_base.size() - 1:

			var direcao: Vector2 = (
				pontos_base[i + 1]
				- pontos_base[i]
			).normalized()

			normal = direcao.orthogonal()


		esquerda.append(
			pontos_base[i] + normal * metade
		)

		direita.insert(
			0,
			pontos_base[i] - normal * metade
		)


	return PackedVector2Array(
		esquerda + direita
	)


#====================================


#========== APAGAR DESENHOS ==========

func apagar_todos_desenhos() -> void:

	# Percorre todos os elementos desenhados.
	for elemento in elementos_desenhados:

		# Verifica se o elemento ainda existe.
		if is_instance_valid(elemento):

			# Remove o elemento da cena.
			elemento.queue_free()


	# Limpa a lista.
	elementos_desenhados.clear()


#====================================
