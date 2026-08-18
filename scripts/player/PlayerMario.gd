extends CharacterBody2D
# Player com movimento inspirado no Mario clássico.
# Inclui:
# - Velocidade normal e velocidade de corrida
# - Aceleração progressiva
# - Derrapagem ao inverter a direção
# - Pulo variável ao segurar o botão
# - Controle aéreo
# - Coyote Time
# - Jump Buffer


# ============================================================
# VELOCIDADE HORIZONTAL
# ============================================================

@export_category("Velocidade Horizontal")

# Velocidade máxima andando.
@export var velocidade_normal: float = 90.0

# Velocidade máxima segurando o botão de corrida.
@export var velocidade_correndo: float = 150.0

# Aceleração normal.
@export var aceleracao: float = 600.0

# Aceleração durante a corrida.
@export var aceleracao_correndo: float = 750.0

# Desaceleração normal.
@export var desaceleracao: float = 500.0

# Desaceleração ao inverter a direção.
# É o que cria a sensação de derrapagem.
@export var desaceleracao_derrapagem: float = 900.0

# Controle horizontal no ar.
@export_range(0.0, 1.0, 0.01)
var controle_no_ar: float = 0.55


# ============================================================
# CORRIDA
# ============================================================

@export_category("Corrida")

# Permite correr segurando o botão.
@export var permitir_corrida: bool = true

# A velocidade de corrida só é alcançada enquanto
# o botão de corrida estiver pressionado.
@export var exigir_botao_corrida: bool = true


# ============================================================
# DERRAPAGEM
# ============================================================

@export_category("Derrapagem")

# Ativa a derrapagem ao inverter a direção.
@export var usar_derrapagem: bool = true

# Velocidade mínima necessária para iniciar a derrapagem.
@export var velocidade_minima_derrapagem: float = 50.0

# Indica se o personagem está derrapando.
var derrapando: bool = false


# ============================================================
# PULO
# ============================================================

@export_category("Pulo")

# Força inicial do pulo.
@export var impulso_pulo: float = -300.0

# Pulo pode ter altura diferente dependendo de quanto
# tempo o botão é segurado.
@export var pulo_variavel: bool = true

# Multiplicador utilizado quando o botão é solto
# durante a subida.
@export_range(0.0, 1.0, 0.01)
var multiplicador_pulo_curto: float = 0.45

# Tempo máximo em que segurar o botão pode prolongar o salto.
@export var tempo_pulo_alto: float = 0.28

# Gravidade enquanto o botão de pulo está sendo segurado.
@export var gravidade_pulo_seguro: float = 600.0


# ============================================================
# GRAVIDADE
# ============================================================

@export_category("Gravidade")

# Gravidade normal.
@export var gravidade: float = 850.0

# Gravidade durante a subida quando o botão não está sendo
# segurado.
@export var gravidade_subindo: float = 1.0

# Gravidade durante a queda.
@export var gravidade_caindo: float = 1.15

# Velocidade máxima de queda.
@export var velocidade_maxima_queda: float = 650.0


# ============================================================
# CONTROLE DO PULO
# ============================================================

@export_category("Controle do Pulo")

# Permite pular por alguns instantes depois de sair da plataforma.
@export var tempo_coyote: float = 0.08

# Guarda o comando de pulo por alguns instantes.
@export var tempo_buffer_pulo: float = 0.10


# ============================================================
# VARIÁVEIS INTERNAS
# ============================================================

# Direção horizontal atual.
var direcao_horizontal: float = 0.0

# Indica se o botão de corrida está sendo segurado.
var is_running: bool = false

# Tempo que o botão de pulo está sendo segurado.
var tempo_pulo: float = 0.0

# Indica se o personagem está atualmente pulando.
var pulando: bool = false

# Temporizador do Coyote Time.
var coyote_timer: float = 0.0

# Temporizador do Jump Buffer.
var jump_buffer_timer: float = 0.0


# ============================================================
# PROCESSAMENTO PRINCIPAL
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

	# Atualiza o Coyote Time.
	atualizar_coyote()


# ============================================================
# MOVIMENTO HORIZONTAL
# ============================================================

func processar_movimento_horizontal(delta: float) -> void:

	# Obtém a direção através das ações configuradas.
	#
	# andar_traz   = A / Left
	# andar_frente = D / Right
	direcao_horizontal = Input.get_axis(
		"andar_traz",
		"andar_frente"
	)


	# ========================================================
	# CORRIDA
	# ========================================================

	# Shift determina se o personagem está correndo.
	if permitir_corrida:

		is_running = Input.is_action_pressed("correr")

	else:

		is_running = false


	# Define a velocidade máxima.
	var velocidade_alvo: float

	if is_running:

		velocidade_alvo = velocidade_correndo

	else:

		velocidade_alvo = velocidade_normal


	# ========================================================
	# SEM MOVIMENTO
	# ========================================================

	if direcao_horizontal == 0.0:

		derrapando = false

		# Desacelera naturalmente.
		velocity.x = move_toward(
			velocity.x,
			0.0,
			desaceleracao * delta
		)

		return


	# ========================================================
	# DETECTAR INVERSÃO
	# ========================================================

	var invertendo_direcao: bool = (
		velocity.x != 0.0
		and sign(velocity.x) != direcao_horizontal
	)


	# ========================================================
	# DERRAPAGEM
	# ========================================================

	if (
		usar_derrapagem
		and is_on_floor()
		and invertendo_direcao
		and abs(velocity.x) >= velocidade_minima_derrapagem
	):

		# O personagem ainda mantém parte da velocidade antiga
		# enquanto começa a inverter a direção.
		derrapando = true

		velocity.x = move_toward(
			velocity.x,
			0.0,
			desaceleracao_derrapagem * delta
		)

		return


	# Quando deixa de inverter, termina a derrapagem.
	derrapando = false


	# ========================================================
	# MOVIMENTO NO CHÃO
	# ========================================================

	if is_on_floor():

		var aceleracao_atual: float

		if is_running:

			aceleracao_atual = aceleracao_correndo

		else:

			aceleracao_atual = aceleracao


		# Acelera até a velocidade desejada.
		velocity.x = move_toward(
			velocity.x,
			direcao_horizontal * velocidade_alvo,
			aceleracao_atual * delta
		)


	# ========================================================
	# MOVIMENTO NO AR
	# ========================================================

	else:

		# O controle aéreo é menor.
		velocity.x = move_toward(
			velocity.x,
			direcao_horizontal * velocidade_alvo,
			aceleracao * controle_no_ar * delta
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

		# Enquanto o jogador estiver segurando o botão,
		# a gravidade é menor e o salto fica mais alto.
		if (
			pulando
			and Input.is_action_pressed("pulo")
			and tempo_pulo < tempo_pulo_alto
		):

			velocity.y += (
				gravidade_pulo_seguro
				* delta
			)

		else:

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

		# Limita a velocidade máxima da queda.
		velocity.y = min(
			velocity.y,
			velocidade_maxima_queda
		)


# ============================================================
# PULO
# ============================================================

func processar_pulo() -> void:

	# Guarda o comando de pulo.
	if Input.is_action_just_pressed("pulo"):

		jump_buffer_timer = tempo_buffer_pulo


	# Não existe comando armazenado.
	if jump_buffer_timer <= 0.0:

		return


	# Verifica se pode pular.
	if pode_pular():

		# Aplica o impulso.
		velocity.y = impulso_pulo

		# Começa o controle do salto.
		pulando = true

		# Zera o contador.
		tempo_pulo = 0.0

		# Consome o comando.
		jump_buffer_timer = 0.0

		# Consome o Coyote Time.
		coyote_timer = 0.0


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


	return false


# ============================================================
# CONTROLE DO PULO
# ============================================================

func _input(event: InputEvent) -> void:

	# Verifica se o pulo variável está ativado.
	if not pulo_variavel:

		return


	# ========================================================
	# SOLTAR O BOTÃO
	# ========================================================

	if event.is_action_released("pulo"):

		# Se ainda estiver subindo, corta o salto.
		if velocity.y < 0.0:

			velocity.y *= multiplicador_pulo_curto

		# O salto deixa de ser prolongado.
		pulando = false


# ============================================================
# ATUALIZAR COYOTE TIME
# ============================================================

func atualizar_coyote() -> void:

	if is_on_floor():

		coyote_timer = tempo_coyote


# ============================================================
# TEMPORIZADORES
# ============================================================

func atualizar_temporizadores(delta: float) -> void:

	# Atualiza o Coyote Time.
	if coyote_timer > 0.0:

		coyote_timer -= delta


	# Atualiza o Jump Buffer.
	if jump_buffer_timer > 0.0:

		jump_buffer_timer -= delta


	# Atualiza o tempo do pulo.
	if pulando:

		tempo_pulo += delta
