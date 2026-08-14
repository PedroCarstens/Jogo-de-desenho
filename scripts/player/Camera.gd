extends Camera2D

class_name CameraController


# ============================================================
# CONFIGURAÇÃO DA CÂMERA
# ============================================================
# A câmera acompanha o jogador de maneira suave.
#
# Ela possui uma área de tolerância para que o jogador
# possa se movimentar sem a câmera ficar constantemente
# tentando corrigir sua posição.
# ============================================================

@export_category("Acompanhamento")

# Referência para o jogador que a câmera deve acompanhar.
@export var jogador: CharacterBody2D

# Distância horizontal que o jogador pode percorrer
# antes da câmera começar a acompanhá-lo.
#
# Quanto maior o valor, mais livre o jogador fica
# antes da câmera começar a se mover.
@export var margem_horizontal: float = 120.0

# Distância vertical que o jogador pode percorrer
# antes da câmera começar a acompanhá-lo.
@export var margem_vertical: float = 80.0

# Velocidade de acompanhamento horizontal.
#
# Valores maiores fazem a câmera reagir mais rapidamente.
@export var suavidade_horizontal: float = 5.0

# Velocidade de acompanhamento vertical.
#
# Normalmente usamos um valor menor que o horizontal
# para deixar a câmera mais suave.
@export var suavidade_vertical: float = 3.0


# ============================================================
# ANTECIPAÇÃO
# ============================================================
# A câmera pode olhar um pouco para frente na direção
# em que o jogador está se movimentando.
# ============================================================

@export_category("Antecipação")

# Distância que a câmera olha para frente.
@export var antecipacao_horizontal: float = 60.0

# Velocidade com que a antecipação muda.
@export var suavidade_antecipacao: float = 4.0

# Ativa ou desativa a antecipação.
@export var usar_antecipacao: bool = true


# ============================================================
# VARIÁVEIS INTERNAS
# ============================================================

# Posição desejada da câmera.
var camera_alvo: Vector2

# Antecipação atual da câmera.
var antecipacao_atual: float = 0.0


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:

	# Começa a câmera na posição em que ela foi colocada
	# na cena.
	camera_alvo = global_position


# ============================================================
# LOOP DA CÂMERA
# ============================================================

func _process(delta: float) -> void:

	# Verifica se existe um jogador configurado.
	if jogador == null:

		return

	# Atualiza a câmera.
	atualizar_camera(delta)


# ============================================================
# ATUALIZAÇÃO DA CÂMERA
# ============================================================

func atualizar_camera(delta: float) -> void:

	# Atualiza a antecipação.
	atualizar_antecipacao(delta)

	# Começa utilizando a posição atual da câmera.
	camera_alvo = global_position


	# ========================================================
	# DISTÂNCIA HORIZONTAL
	# ========================================================

	# Calcula a distância entre o jogador e o centro
	# da câmera.
	var diferenca_x: float = (
		jogador.global_position.x
		- global_position.x
	)


	# Verifica se o jogador ultrapassou a margem horizontal.
	if abs(diferenca_x) > margem_horizontal:

		# Define uma nova posição horizontal para a câmera.
		camera_alvo.x = (
			jogador.global_position.x
			- antecipacao_atual
		)


	# ========================================================
	# DISTÂNCIA VERTICAL
	# ========================================================

	# Calcula a distância vertical entre o jogador
	# e a câmera.
	var diferenca_y: float = (
		jogador.global_position.y
		- global_position.y
	)


	# Verifica se o jogador ultrapassou a margem vertical.
	if abs(diferenca_y) > margem_vertical:

		# Define a posição vertical desejada.
		camera_alvo.y = jogador.global_position.y


	# ========================================================
	# MOVIMENTO SUAVE
	# ========================================================

	# Move horizontalmente suavemente.
	global_position.x = lerpf(
		global_position.x,
		camera_alvo.x,
		suavidade_horizontal * delta
	)

	# Move verticalmente suavemente.
	global_position.y = lerpf(
		global_position.y,
		camera_alvo.y,
		suavidade_vertical * delta
	)


# ============================================================
# ANTECIPAÇÃO
# ============================================================

func atualizar_antecipacao(delta: float) -> void:

	# Valor que queremos alcançar normalmente.
	var alvo_antecipacao: float = 0.0


	# Verifica se a antecipação está ativada.
	if usar_antecipacao:

		# Verifica se o jogador está se movimentando.
		if jogador.velocity.x != 0.0:

			# Obtém somente a direção do movimento.
			var direcao: float = sign(jogador.velocity.x)

			# Define a antecipação normal.
			alvo_antecipacao = (
				direcao
				* antecipacao_horizontal
			)


	# ========================================================
	# ANTECIPAÇÃO DURANTE CORRIDA
	# ========================================================

	var alvo_corrida: float = 0.0

	# Verifica se o jogador está correndo.
	if jogador.is_running:

		# Adiciona uma antecipação extra na direção
		# em que o personagem está se movimentando.
		if jogador.velocity.x != 0.0:

			var direcao: float = sign(jogador.velocity.x)

			alvo_corrida = (
				direcao
				* antecipacao_correndo
			)


	# Move a antecipação normal suavemente.
	antecipacao_atual = lerpf(
		antecipacao_atual,
		alvo_antecipacao,
		suavidade_antecipacao * delta
	)


	# Move a antecipação adicional da corrida suavemente.
	antecipacao_corrida_atual = lerpf(
		antecipacao_corrida_atual,
		alvo_corrida,
		suavidade_corrida_camera * delta
	)
	# ============================================================
# CÂMERA DURANTE CORRIDA
# ============================================================
# Quando o jogador estiver correndo, a câmera aumenta
# levemente sua antecipação para mostrar mais do cenário
# à frente.
# ============================================================

@export_category("Corrida")

# Distância adicional que a câmera olha para frente
# enquanto o jogador está correndo.
@export var antecipacao_correndo: float = 40.0

# Velocidade com que a câmera entra e sai do modo de corrida.
@export var suavidade_corrida_camera: float = 4.0

# Guarda a antecipação adicional atual da corrida.
var antecipacao_corrida_atual: float = 0.0
