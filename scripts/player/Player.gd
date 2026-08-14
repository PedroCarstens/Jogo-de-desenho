extends CharacterBody2D

class_name Player
# Define a classe Player associada ao CharacterBody2D.


# ============================================================
# VELOCIDADE HORIZONTAL
# ============================================================
# Define como o personagem se movimenta para os lados.
# ============================================================

@export_category("Velocidade Horizontal")

# Velocidade máxima andando.
@export var velocidade_normal: float = 200.0

# Velocidade máxima correndo.
@export var velocidade_correndo: float = 350.0

# Força utilizada para acelerar o personagem.
@export var aceleracao: float = 1200.0

# Força utilizada para desacelerar o personagem.
@export var desaceleracao: float = 1500.0

# Controle horizontal enquanto estiver no ar.
# 1.0 = controle total / 0.0 = nenhum controle.
@export_range(0.0, 1.0, 0.05) var controle_no_ar: float = 0.8


# ============================================================
# PULO
# ============================================================

@export_category("Pulo")

# Impulso inicial do salto.
@export var impulso_pulo: float = -400.0

# Quantidade de pulos disponíveis.
@export_range(1, 5, 1) var quantidade_pulos: int = 1

# Permite controlar a altura do salto soltando o botão.
@export var pulo_variavel: bool = true

# Quanto da velocidade será mantida ao soltar o botão de pulo.
@export_range(0.0, 1.0, 0.05) var multiplicador_pulo_curto: float = 0.5


# ============================================================
# GRAVIDADE
# ============================================================

@export_category("Gravidade")

# Força da gravidade.
@export var gravidade: float = 1000.0

# Multiplicador da gravidade enquanto o personagem sobe.
@export_range(0.1, 2.0, 0.05) var gravidade_subindo: float = 1.0

# Multiplicador da gravidade enquanto o personagem cai.
@export_range(0.1, 3.0, 0.05) var gravidade_caindo: float = 1.0

# Limite máximo da velocidade de queda.
@export var velocidade_maxima_queda: float = 1200.0


# ============================================================
# TOLERÂNCIA DO PULO
# ============================================================
# Pequenas tolerâncias deixam o controle mais responsivo.
# ============================================================

@export_category("Tolerância do Pulo")

# Tempo em que o jogador ainda pode pular depois de sair
# de uma plataforma.
@export_range(0.0, 0.5, 0.01) var tempo_coyote: float = 0.12

# Tempo em que o comando de pulo fica armazenado antes de tocar no chão.
@export_range(0.0, 0.5, 0.01) var tempo_buffer_pulo: float = 0.12


# ============================================================
# VARIÁVEIS INTERNAS
# ============================================================

# Quantidade de pulos utilizados atualmente.
var pulos_realizados: int = 0

# Temporizador do Coyote Time.
var coyote_timer: float = 0.0

# Temporizador do Jump Buffer.
var jump_buffer_timer: float = 0.0

# Direção horizontal atual.
var direcao_horizontal: float = 0.0

# Indica se o personagem está correndo.
# Também é utilizado pela câmera para alterar a antecipação.
var is_running: bool = false


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:

	# Inicializa a quantidade de pulos.
	pulos_realizados = 0


# ============================================================
# LOOP PRINCIPAL
# ============================================================

func _physics_process(delta: float) -> void:

	# Atualiza os temporizadores.
	atualizar_temporizadores(delta)

	# Processa o movimento horizontal.
	processar_movimento_horizontal(delta)

	# Processa a gravidade.
	processar_gravidade(delta)

	# Processa o pulo.
	processar_pulo()

	# Move o personagem.
	move_and_slide()

	# Atualiza os pulos disponíveis.
	atualizar_estado_no_chao()


# ============================================================
# MOVIMENTO HORIZONTAL
# ============================================================

func processar_movimento_horizontal(delta: float) -> void:

	# Obtém a direção através das ações configuradas no Input Map.
	# andar_traz = A / Left
	# andar_frente = D / Right
	direcao_horizontal = Input.get_axis(
		"andar_traz",
		"andar_frente"
	)


	# ========================================================
	# CORRIDA
	# ========================================================

	# Verifica se o jogador está segurando o botão de correr.
	is_running = Input.is_action_pressed("correr")


	# ========================================================
	# VELOCIDADE ATUAL
	# ========================================================

	var velocidade_atual: float

	# Se estiver correndo, utiliza a velocidade de corrida.
	if is_running:
		velocidade_atual = velocidade_correndo
	else:
		velocidade_atual = velocidade_normal


	# ========================================================
	# MOVIMENTO NO CHÃO
	# ========================================================

	if is_on_floor():

		# Existe uma direção sendo pressionada.
		if direcao_horizontal != 0.0:

			# Acelera suavemente até a velocidade desejada.
			velocity.x = move_toward(
				velocity.x,
				direcao_horizontal * velocidade_atual,
				aceleracao * delta
			)

		# Nenhuma direção está sendo pressionada.
		else:

			# Desacelera suavemente até parar.
			velocity.x = move_toward(
				velocity.x,
				0.0,
				desaceleracao * delta
			)


	# ========================================================
	# MOVIMENTO NO AR
	# ========================================================

	else:

		# Existe uma direção sendo pressionada.
		if direcao_horizontal != 0.0:

			# Mantém controle sobre o personagem no ar.
			velocity.x = move_toward(
				velocity.x,
				direcao_horizontal * velocidade_atual,
				aceleracao * controle_no_ar * delta
			)

		# Nenhuma direção está sendo pressionada.
		else:

			# Desacelera também durante o movimento aéreo.
			velocity.x = move_toward(
				velocity.x,
				0.0,
				desaceleracao * controle_no_ar * delta
			)


# ============================================================
# GRAVIDADE
# ============================================================

func processar_gravidade(delta: float) -> void:

	# Não aplica gravidade no chão.
	if is_on_floor():
		return


	# ========================================================
	# SUBIDA
	# ========================================================

	if velocity.y < 0.0:

		velocity.y += (
			gravidade
			* gravidade_subindo
			* delta
		)


	# ========================================================
	# QUEDA
	# ========================================================

	else:

		velocity.y += (
			gravidade
			* gravidade_caindo
			* delta
		)

		# Impede uma velocidade de queda exagerada.
		velocity.y = min(
			velocity.y,
			velocidade_maxima_queda
		)


# ============================================================
# SISTEMA DE PULO
# ============================================================

func processar_pulo() -> void:

	# Verifica se o jogador pressionou o botão de pulo.
	if Input.is_action_just_pressed("pulo"):
		jump_buffer_timer = tempo_buffer_pulo


	# Verifica se existe um comando armazenado.
	if jump_buffer_timer <= 0.0:
		return


	# Verifica se o jogador pode pular.
	if pode_pular():

		# Executa o salto.
		executar_pulo()

		# Consome o comando armazenado.
		jump_buffer_timer = 0.0


# ============================================================
# VERIFICAR PULO
# ============================================================

func pode_pular() -> bool:

	# Pulo normal no chão.
	if is_on_floor():
		return true

	# Pulo durante o Coyote Time.
	if coyote_timer > 0.0:
		return true

	# Pulos adicionais.
	if pulos_realizados < quantidade_pulos:
		return true

	return false


# ============================================================
# EXECUTAR PULO
# ============================================================

func executar_pulo() -> void:

	# Aplica o impulso vertical.
	velocity.y = impulso_pulo

	# Registra o pulo.
	pulos_realizados += 1

	# Consome o Coyote Time.
	coyote_timer = 0.0


# ============================================================
# PULO VARIÁVEL
# ============================================================

func _input(event: InputEvent) -> void:

	# Verifica se o pulo variável está ativado.
	if not pulo_variavel:
		return


	# Verifica se o botão de pulo foi solto.
	if event.is_action_released("pulo"):

		# Verifica se o personagem ainda está subindo.
		if velocity.y < 0.0:

			# Reduz a velocidade para encurtar o salto.
			velocity.y *= multiplicador_pulo_curto


# ============================================================
# ESTADO DO CHÃO
# ============================================================

func atualizar_estado_no_chao() -> void:

	# Quando toca no chão, restaura os pulos.
	if is_on_floor():
		pulos_realizados = 0


# ============================================================
# TEMPORIZADORES
# ============================================================

func atualizar_temporizadores(delta: float) -> void:

	# Reduz o Coyote Time.
	if coyote_timer > 0.0:
		coyote_timer -= delta

	# Reduz o Jump Buffer.
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
