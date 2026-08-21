extends Camera2D
# Câmera inspirada no comportamento do Super Mario Bros. clássico.
#
# A câmera não fica presa diretamente ao jogador.
# Ela espera o jogador chegar a uma área da tela e então acompanha.
# Isso evita a sensação de câmera tremendo/flicando na borda.
#
# Os principais valores ficam exportados para serem ajustados
# diretamente no Inspector da Godot.


# ============================================================
# JOGADOR
# ============================================================

@export_category("Jogador")

# Referência ao jogador que a câmera acompanha.
@export var jogador: CharacterBody2D


# ============================================================
# TAMANHO / ENQUADRAMENTO
# ============================================================

@export_category("Tamanho da Câmera")

# Zoom da câmera.
# Aumentar o valor mostra menos do cenário.
# Diminuir o valor mostra mais do cenário.
@export var zoom_mario: Vector2 = Vector2(2.0, 2.0)

# Posição horizontal do centro da área de acompanhamento.
# 0.5 = centro da tela.
@export_range(0.0, 1.0, 0.01)
var centro_horizontal: float = 0.50

# Posição vertical do centro da área de acompanhamento.
@export_range(0.0, 1.0, 0.01)
var centro_vertical: float = 0.50


# ============================================================
# ÁREA DE ACOMPANHAMENTO
# ============================================================
# O Mario clássico não fica exatamente no centro o tempo todo.
# Ele possui uma área da tela onde pode se mover sem deslocar
# a câmera.
# ============================================================

@export_category("Área de Acompanhamento")

# Quanto da largura da tela o jogador pode percorrer antes
# de a câmera começar a acompanhar.
@export_range(0.0, 0.9, 0.01)
var margem_horizontal: float = 0.20

# Quanto da altura da tela o jogador pode percorrer antes
# de a câmera começar a acompanhar verticalmente.
@export_range(0.0, 0.9, 0.01)
var margem_vertical: float = 0.30

# Permite acompanhamento vertical.
# No Mario clássico a câmera horizontal é muito mais importante.
@export var acompanhar_vertical: bool = true


# ============================================================
# MOVIMENTO DA CÂMERA
# ============================================================

@export_category("Movimento")

# Ativa suavização.
# Desativado fica mais próximo do comportamento rígido do Mario.
@export var usar_suavizacao: bool = false

# Velocidade horizontal caso a suavização esteja ativada.
@export var velocidade_horizontal: float = 8.0

# Velocidade vertical caso a suavização esteja ativada.
@export var velocidade_vertical: float = 6.0

# Faz a câmera acompanhar apenas quando o jogador avança.
# Isso deixa o comportamento mais próximo do Mario clássico.
@export var travar_recuo_horizontal: bool = true


# ============================================================
# LIMITES DA FASE
# ============================================================

@export_category("Limites da Fase")

# Ativa os limites da câmera.
@export var usar_limites: bool = true

# Limite esquerdo do mundo.
@export var limite_esquerdo: float = 0.0

# Limite superior do mundo.
@export var limite_superior: float = 0.0

# Limite direito do mundo.
# Ajuste para o fim real da fase.
@export var limite_direito: float = 3704.0

# Limite inferior do mundo.
@export var limite_inferior: float = 720.0


# ============================================================
# VARIÁVEIS INTERNAS
# ============================================================

# Posição horizontal que a câmera já alcançou.
var ultima_posicao_x: float = 0.0

# Indica se a câmera já foi inicializada.
var camera_inicializada: bool = false


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:

	# Aplica o zoom configurado no Inspector.
	zoom = zoom_mario

	# Configura os limites da câmera.
	if usar_limites:
		limit_left = int(limite_esquerdo)
		limit_top = int(limite_superior)
		limit_right = int(limite_direito)
		limit_bottom = int(limite_inferior)

	# Se não houver jogador configurado, tenta encontrar um.
	if jogador == null:
		jogador = get_parent().get_node_or_null("Player")

	# Começa exatamente na posição atual.
	ultima_posicao_x = global_position.x
	camera_inicializada = true


# ============================================================
# PROCESSAMENTO
# ============================================================

func _process(delta: float) -> void:

	# Não faz nada sem jogador.
	if jogador == null:
		return

	# Atualiza o acompanhamento.
	atualizar_camera(delta)


# ============================================================
# ATUALIZAR CÂMERA
# ============================================================

func atualizar_camera(delta: float) -> void:

	# Calcula o tamanho visível do mundo.
	# O tamanho efetivo muda de acordo com o zoom.
	var tamanho_viewport: Vector2 = get_viewport_rect().size / zoom

	# Define o centro da área de acompanhamento.
	var centro: Vector2 = Vector2(
		tamanho_viewport.x * centro_horizontal,
		tamanho_viewport.y * centro_vertical
	)

	# Define as margens da área de acompanhamento.
	var margem: Vector2 = Vector2(
		tamanho_viewport.x * margem_horizontal,
		tamanho_viewport.y * margem_vertical
	)

	# Calcula os limites da área onde o jogador pode se mover
	# sem deslocar a câmera.
	var area_esquerda: float = global_position.x + centro.x - tamanho_viewport.x * 0.5 - margem.x
	var area_direita: float = global_position.x + centro.x - tamanho_viewport.x * 0.5 + margem.x
	var area_cima: float = global_position.y + centro.y - tamanho_viewport.y * 0.5 - margem.y
	var area_baixo: float = global_position.y + centro.y - tamanho_viewport.y * 0.5 + margem.y

	# Posição desejada começa na posição atual.
	var alvo: Vector2 = global_position


	# ========================================================
	# MOVIMENTO HORIZONTAL
	# ========================================================

	# Se o jogador passou da área direita, a câmera avança.
	if jogador.global_position.x > area_direita:

		var deslocamento: float = (
			jogador.global_position.x
			- area_direita
		)

		alvo.x += deslocamento


	# Se o recuo estiver liberado, a câmera também pode voltar.
	elif (
		jogador.global_position.x < area_esquerda
		and not travar_recuo_horizontal
	):

		var deslocamento: float = (
			jogador.global_position.x
			- area_esquerda
		)

		alvo.x += deslocamento


	# ========================================================
	# MOVIMENTO VERTICAL
	# ========================================================

	if acompanhar_vertical:

		# Jogador passou da parte inferior da área.
		if jogador.global_position.y > area_baixo:

			alvo.y += (
			jogador.global_position.y
			- area_baixo
			)

		# Jogador passou da parte superior da área.
		elif jogador.global_position.y < area_cima:

			alvo.y += (
			jogador.global_position.y
			- area_cima
			)


	# ========================================================
	# APLICAR MOVIMENTO
	# ========================================================

	if usar_suavizacao:

		# Movimento suave opcional.
		global_position.x = lerpf(
			global_position.x,
			alvo.x,
			1.0 - exp(-velocidade_horizontal * delta)
		)

		global_position.y = lerpf(
			global_position.y,
			alvo.y,
			1.0 - exp(-velocidade_vertical * delta)
		)

	else:

		# Movimento direto, mais próximo da câmera clássica.
		global_position = alvo


	# ========================================================
	# TRAVAR RECUO
	# ========================================================

	if travar_recuo_horizontal:

		# Nunca deixa a câmera voltar para trás.
		global_position.x = max(
			global_position.x,
			ultima_posicao_x
		)


	# Guarda a posição mais avançada.
	ultima_posicao_x = max(
		ultima_posicao_x,
		global_position.x
	)
