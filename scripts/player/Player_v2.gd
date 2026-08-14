extends CharacterBody2D


# ============================================================
# MOVIMENTO DO PERSONAGEM
# ============================================================
# Script responsável pelo movimento horizontal e vertical
# do personagem.
#
# Os principais parâmetros estão como @export para permitir
# alterações diretamente pelo Inspector da Godot.
#
# Ações utilizadas no Input Map:
# andar_frente -> D / Right
# andar_traz   -> A / Left
# pulo         -> Space / W / Up
# correr       -> Shift
# ============================================================


# ============================================================
# MOVIMENTO
# ============================================================

@export_category("Movimento")

# Velocidade máxima normal do personagem.
@export var velocidade_maxima: float = 250.0

# Velocidade utilizada para acelerar o personagem.
@export var aceleracao: float = 1500.0

# Velocidade utilizada para desacelerar o personagem
# quando nenhuma direção estiver sendo pressionada.
@export var desaceleracao: float = 1800.0

# Permite inverter os controles horizontais.
@export var inverter_movimento: bool = false


# ============================================================
# CORRIDA
# ============================================================

@export_category("Corrida")

# Multiplicador aplicado à velocidade enquanto o jogador
# estiver segurando o botão de correr.
#
# Exemplo:
# 1.0 = velocidade normal
# 1.5 = 50% mais rápido
# 2.0 = velocidade dobrada
@export_range(1.0, 3.0, 0.1) var multiplicador_corrida: float = 1.5


# ============================================================
# GRAVIDADE
# ============================================================

@export_category("Gravidade")

# Gravidade aplicada ao personagem.
#
# Esse valor representa a força que faz o personagem
# retornar para o chão.
@export var gravidade: float = 1200.0

# Gravidade utilizada enquanto o personagem está subindo.
#
# Um valor menor deixa o salto mais suave e flutuante.
@export var gravidade_subindo: float = 900.0

# Gravidade utilizada enquanto o personagem está caindo.
#
# Um valor maior faz o personagem cair mais rapidamente.
@export var gravidade_caindo: float = 1400.0


# ============================================================
# PULO
# ============================================================

@export_category("Pulo")

# Força inicial aplicada ao personagem quando ele pula.
@export var forca_pulo: float = 450.0

# Quantidade máxima de pulos disponíveis.
#
# 1 = pulo normal
# 2 = pulo duplo
# 3 = pulo triplo
@export_range(1, 5, 1) var quantidade_pulos: int = 1

# Permite controlar a altura do pulo soltando o botão
# antes que o personagem atinja o ponto máximo.
@export var pulo_variavel: bool = true

# Multiplicador utilizado quando o jogador solta o botão
# de pulo antes do personagem atingir o ponto máximo.
#
# Valores menores fazem o salto ser interrompido
# mais rapidamente.
@export_range(0.0, 1.0, 0.05) var multiplicador_pulo_curto: float = 0.5


# ============================================================
# TOLERÂNCIA DO PULO
# ============================================================

@export_category("Tolerância do Pulo")

# Tempo durante o qual o jogador ainda pode pular depois
# de sair da plataforma.
#
# Esse sistema é conhecido como "Coyote Time".
@export_range(0.0, 0.5, 0.01) var tempo_coyote: float = 0.12

# Tempo durante o qual o jogo guarda o comando de pulo
# caso o jogador pressione o botão um pouco antes de
# tocar no chão.
#
# Esse sistema é conhecido como "Jump Buffer".
@export_range(0.0, 0.5, 0.01) var tempo_buffer_pulo: float = 0.12


# ============================================================
# DEBUG
# ============================================================

@export_category("Debug")

# Ativa informações do movimento no console da Godot.
@export var mostrar_debug: bool = false


# ============================================================
# VARIÁVEIS INTERNAS
# ============================================================

# Quantidade de pulos utilizados atualmente.
var pulos_realizados: int = 0

# Tempo restante do Coyote Time.
var coyote_timer: float = 0.0

# Tempo restante do Jump Buffer.
var jump_buffer_timer: float = 0.0


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:

	# Inicializa a quantidade de pulos utilizados.
	pulos_realizados = 0


# ============================================================
# LOOP PRINCIPAL
# ============================================================

func _physics_process(delta: float) -> void:

	# Atualiza os temporizadores do sistema de movimento.
	atualizar_temporizadores(delta)

	# Processa o movimento horizontal.
	processar_movimento_horizontal(delta)

	# Processa a gravidade.
	processar_gravidade(delta)

	# Processa o pulo.
	processar_pulo()

	# Aplica o movimento do personagem e verifica colisões.
	move_and_slide()

	# Atualiza o estado do personagem depois do movimento.
	atualizar_estado_no_chao()

	# Mostra informações de debug caso esteja ativado.
	if mostrar_debug:
		mostrar_informacoes_debug()


# ============================================================
# MOVIMENTO HORIZONTAL
# ============================================================

func processar_movimento_horizontal(delta: float) -> void:

	# Obtém a direção horizontal utilizando as ações
	# configuradas no Input Map.
	#
	# andar_traz   = A / Left
	# andar_frente = D / Right
	var direcao := Input.get_axis("andar_traz", "andar_frente")

	# Inverte o controle caso essa opção esteja ativada.
	if inverter_movimento:
		direcao *= -1.0

	# Calcula a velocidade desejada.
	var velocidade_desejada := direcao * velocidade_atual()

	# Caso o jogador esteja pressionando uma direção,
	# utiliza a aceleração.
	if direcao != 0.0:

		velocity.x = move_toward(
			velocity.x,
			velocidade_desejada,
			aceleracao * delta
		)

	# Caso nenhuma direção esteja sendo pressionada,
	# desacelera o personagem.
	else:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			desaceleracao * delta
		)


# ============================================================
# VELOCIDADE ATUAL
# ============================================================

func velocidade_atual() -> float:

	# Verifica se o jogador está segurando o botão de correr.
	if Input.is_action_pressed("correr"):

		# Aplica o multiplicador de corrida.
		return velocidade_maxima * multiplicador_corrida

	# Caso contrário, utiliza a velocidade normal.
	return velocidade_maxima


# ============================================================
# GRAVIDADE
# ============================================================

func processar_gravidade(delta: float) -> void:

	# Se o personagem estiver no chão, não precisamos
	# aplicar gravidade.
	if is_on_floor():
		return

	# Verifica se o personagem está subindo.
	if velocity.y < 0.0:

		# Aplica a gravidade utilizada durante a subida.
		velocity.y += gravidade_subindo * delta

	# Caso contrário, o personagem está caindo.
	else:

		# Aplica a gravidade utilizada durante a queda.
		velocity.y += gravidade_caindo * delta


# ============================================================
# SISTEMA DE PULO
# ============================================================

func processar_pulo() -> void:

	# Verifica se o jogador pressionou uma das teclas
	# associadas à ação "pulo".
	#
	# Space / W / Up
	if Input.is_action_just_pressed("pulo"):

		# Guarda o comando de pulo durante um pequeno período.
		jump_buffer_timer = tempo_buffer_pulo

	# Caso não exista nenhum comando de pulo armazenado,
	# não precisamos continuar.
	if jump_buffer_timer <= 0.0:
		return

	# Verifica se o personagem pode realizar um pulo.
	if pode_pular():

		# Executa o pulo.
		executar_pulo()

		# Consome o comando armazenado.
		jump_buffer_timer = 0.0


# ============================================================
# VERIFICAÇÃO DO PULO
# ============================================================

func pode_pular() -> bool:

	# Permite o pulo normalmente quando o personagem
	# está sobre uma plataforma.
	if is_on_floor():
		return true

	# Permite o pulo durante o Coyote Time.
	if coyote_timer > 0.0:
		return true

	# Permite pulos adicionais quando configurados.
	if pulos_realizados < quantidade_pulos:
		return true

	# Caso nenhuma condição seja satisfeita,
	# o personagem não pode pular.
	return false


# ============================================================
# EXECUTAR PULO
# ============================================================

func executar_pulo() -> void:

	# Aplica a força vertical do pulo.
	velocity.y = -forca_pulo

	# Registra que um pulo foi utilizado.
	pulos_realizados += 1

	# Consome o Coyote Time ao realizar o pulo.
	coyote_timer = 0.0


# ============================================================
# PULO VARIÁVEL
# ============================================================

func _input(event: InputEvent) -> void:

	# Verifica se o sistema de pulo variável está ativado.
	if not pulo_variavel:
		return

	# Verifica se o jogador soltou uma das teclas
	# associadas à ação "pulo".
	if event.is_action_released("pulo"):

		# Verifica se o personagem ainda está subindo.
		if velocity.y < 0.0:

			# Reduz a velocidade vertical para encurtar o pulo.
			velocity.y *= multiplicador_pulo_curto


# ============================================================
# ATUALIZAÇÃO DOS TEMPORIZADORES
# ============================================================

func atualizar_temporizadores(delta: float) -> void:

	# Reduz o tempo restante do Coyote Time.
	if coyote_timer > 0.0:

		coyote_timer -= delta

	# Reduz o tempo restante do Jump Buffer.
	if jump_buffer_timer > 0.0:

		jump_buffer_timer -= delta


# ============================================================
# ESTADO DO CHÃO
# ============================================================

func atualizar_estado_no_chao() -> void:

	# Verifica se o personagem está sobre o chão.
	if is_on_floor():

		# Restaura a quantidade de pulos.
		pulos_realizados = 0

		# Atualiza o Coyote Time.
		coyote_timer = tempo_coyote


# ============================================================
# DEBUG
# ============================================================

func mostrar_informacoes_debug() -> void:

	# Mostra informações importantes do personagem
	# no console da Godot para facilitar os testes.
	print(
		"Velocidade: ",
		velocity,
		" | Pulos: ",
		pulos_realizados,
		" | Coyote: ",
		coyote_timer,
		" | Buffer: ",
		jump_buffer_timer
	)
