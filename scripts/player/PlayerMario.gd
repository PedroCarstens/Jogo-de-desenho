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
# - Corner Correction usando dois RayCast2D
# - Debug de movimentação para facilitar testes no desenvolvimento


# ============================================================
# VELOCIDADE HORIZONTAL
# ============================================================

@export_category("Velocidade Horizontal")

# Velocidade máxima andando.
@export var velocidade_normal: float = 180.0

# Velocidade máxima segurando o botão de corrida.
@export var velocidade_correndo: float = 290.0

# Aceleração normal.
@export var aceleracao: float = 690.0

# Aceleração durante a corrida.
@export var aceleracao_correndo: float = 800.0

# Desaceleração normal.
@export var desaceleracao: float = 500.0

# Desaceleração ao inverter a direção.
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


# ============================================================
# DERRAPAGEM
# ============================================================

@export_category("Derrapagem")

# Ativa a derrapagem ao inverter a direção.
@export var usar_derrapagem: bool = true

# Velocidade mínima necessária para iniciar a derrapagem.
@export var velocidade_minima_derrapagem: float = 90.0

# Indica se o personagem está derrapando.
var derrapando: bool = false


# ============================================================
# PULO
# ============================================================

@export_category("Pulo")

# Força inicial do pulo.
@export var impulso_pulo: float = -500.0

# Permite controlar a altura do pulo segurando o botão.
@export var pulo_variavel: bool = true

# Multiplicador utilizado quando o botão é solto durante a subida.
@export_range(0.0, 1.0, 0.01)
var multiplicador_pulo_curto: float = 0.5

# Tempo máximo em que segurar o botão pode prolongar o salto.
@export var tempo_pulo_alto: float = 0.3

# Gravidade enquanto o botão de pulo está sendo segurado.
@export var gravidade_pulo_seguro: float = 600.0


# ============================================================
# GRAVIDADE
# ============================================================

@export_category("Gravidade")

# Gravidade normal.
@export var gravidade: float = 850.0

# Gravidade durante a subida.
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
@export var tempo_coyote: float = 0.11

# Guarda o comando de pulo por alguns instantes.
@export var tempo_buffer_pulo: float = 0.10


# ============================================================
# CORNER CORRECTION
# ============================================================
# A correção de quina não muda a direção do input.
# Ela desloca o Player alguns pixels para o lado livre quando
# somente um dos cantos superiores encontra uma plataforma.
# Isso evita o "head bonk" e permite que o salto continue.
#
# Os RayCast2D são posicionados automaticamente nos cantos da
# CollisionShape2D e apontam para cima.
# ============================================================

@export_category("Corner Correction")

# Ativa ou desativa a correção de quina.
@export var usar_corner_correction: bool = true

# Distância máxima que o Player pode ser deslocado para o lado.
@export_range(0.0, 24.0, 0.5)
var corner_correction_distancia: float = 16.0

# Comprimento dos RayCast2D para detectar o teto.
@export_range(1.0, 32.0, 0.5)
var corner_correction_altura: float = 16.0

# Quantidade de pequenos testes usados na correção.
@export_range(1, 16, 1)
var corner_correction_tentativas: int = 8

# A correção só acontece enquanto o Player está subindo.
@export var corner_correction_apenas_subindo: bool = true

# Espaço entre o RayCast e a borda exata da CollisionShape2D.
@export_range(0.0, 4.0, 0.5)
var corner_correction_margem: float = 1.0

# Os nomes correspondem exatamente aos RayCast2D da cena atual.
@onready var corner_raycast_direito: RayCast2D = $"RayCast direito"
@onready var corner_raycast_esquerdo: RayCast2D = $"RayCast esquerdo"

# Colisão usada para posicionar automaticamente os dois Rays.
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# ============================================================
# DEBUG / QUALIDADE DE VIDA
# ============================================================
# Ferramentas de diagnóstico para acompanhar a movimentação
# sem precisar alterar a lógica de física.
#
# Os prints acontecem em eventos importantes e não a cada frame,
# evitando encher o Output do Godot desnecessariamente.
# ============================================================

@export_category("Debug - Qualidade de Vida")

# Liga ou desliga todos os prints de diagnóstico.
@export var debug_movimento: bool = true

# Mostra mudanças de direção e velocidade horizontal.
@export var debug_horizontal: bool = true

# Mostra eventos relacionados ao pulo.
@export var debug_pulo: bool = true

# Mostra eventos relacionados à gravidade e estado no ar.
@export var debug_gravidade: bool = true

# Mostra eventos do Coyote Time e Jump Buffer.
@export var debug_temporizadores: bool = true

# Mostra detecção e aplicação do Corner Correction.
@export var debug_corner_correction: bool = true

# Evita repetir mensagens de estado que não mudaram.
var debug_direcao_anterior: float = 0.0
var debug_corrida_anterior: bool = false
var debug_no_chao_anterior: bool = false
var debug_subindo_anterior: bool = false
var debug_derrapando_anterior: bool = false
var debug_buffer_ativo_anterior: bool = false
var debug_coyote_ativo_anterior: bool = false


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
# FUNÇÃO DE DEBUG
# ============================================================

func debug_print(mensagem: String) -> void:
	if debug_movimento:
		print("[PLAYER DEBUG] ", mensagem)


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:
	corner_raycast_direito.enabled = true
	corner_raycast_esquerdo.enabled = true

	configurar_corner_rays()

	debug_no_chao_anterior = is_on_floor()
	debug_print("PlayerMario iniciado.")
	debug_print("Velocidade normal: " + str(velocidade_normal))
	debug_print("Velocidade corrida: " + str(velocidade_correndo))
	debug_print("Corner Correction: " + ("ATIVADO" if usar_corner_correction else "DESATIVADO"))


# ============================================================
# CONFIGURAR RAYCASTS
# ============================================================

func configurar_corner_rays() -> void:
	if collision_shape.shape is RectangleShape2D:
		var forma: RectangleShape2D = collision_shape.shape
		var metade_x: float = forma.size.x * 0.5
		var metade_y: float = forma.size.y * 0.5
		var centro: Vector2 = collision_shape.position

		var topo_y: float = centro.y - metade_y + corner_correction_margem
		var esquerda_x: float = centro.x - metade_x + corner_correction_margem
		var direita_x: float = centro.x + metade_x - corner_correction_margem

		corner_raycast_esquerdo.position = Vector2(esquerda_x, topo_y)
		corner_raycast_direito.position = Vector2(direita_x, topo_y)

	corner_raycast_esquerdo.target_position = Vector2(0.0, -corner_correction_altura)
	corner_raycast_direito.target_position = Vector2(0.0, -corner_correction_altura)

	corner_raycast_esquerdo.force_raycast_update()
	corner_raycast_direito.force_raycast_update()

	if debug_movimento:
		debug_print("RayCast esquerdo configurado: " + str(corner_raycast_esquerdo.position))
		debug_print("RayCast direito configurado: " + str(corner_raycast_direito.position))


# ============================================================
# PROCESSAMENTO PRINCIPAL
# ============================================================

func _physics_process(delta: float) -> void:
	atualizar_temporizadores(delta)
	processar_movimento_horizontal(delta)
	processar_gravidade(delta)
	processar_pulo()
	aplicar_corner_correction()
	move_and_slide()
	atualizar_coyote()
	atualizar_debug_estado()


# ============================================================
# DEBUG DE ESTADO
# ============================================================

func atualizar_debug_estado() -> void:
	if not debug_movimento:
		return

	var no_chao_atual: bool = is_on_floor()
	var subindo_atual: bool = velocity.y < 0.0 and not no_chao_atual

	if no_chao_atual != debug_no_chao_anterior:
		if no_chao_atual:
			debug_print("ESTADO: pousou no chão.")
		else:
			debug_print("ESTADO: saiu do chão.")
		debug_no_chao_anterior = no_chao_atual

	if subindo_atual != debug_subindo_anterior:
		if subindo_atual:
			if debug_gravidade:
				debug_print("GRAVIDADE: começou a subida.")
		else:
			if debug_gravidade and not no_chao_atual:
				debug_print("GRAVIDADE: começou a queda.")
		debug_subindo_anterior = subindo_atual

	if derrapando != debug_derrapando_anterior:
		if debug_horizontal:
			debug_print("DERRAPAGEM: " + ("INICIADA" if derrapando else "ENCERRADA"))
		debug_derrapando_anterior = derrapando


# ============================================================
# MOVIMENTO HORIZONTAL
# ============================================================

func processar_movimento_horizontal(delta: float) -> void:
	direcao_horizontal = Input.get_axis("andar_traz", "andar_frente")

	if permitir_corrida:
		is_running = Input.is_action_pressed("correr")
	else:
		is_running = false

	if debug_horizontal:
		if direcao_horizontal != debug_direcao_anterior:
			if direcao_horizontal > 0.0:
				debug_print("MOVIMENTO: DIREITA")
			elif direcao_horizontal < 0.0:
				debug_print("MOVIMENTO: ESQUERDA")
			else:
				debug_print("MOVIMENTO: PAROU")
			debug_direcao_anterior = direcao_horizontal

		if is_running != debug_corrida_anterior:
			debug_print("CORRIDA: " + ("ATIVADA" if is_running else "DESATIVADA"))
			debug_corrida_anterior = is_running

	var velocidade_alvo: float
	if is_running:
		velocidade_alvo = velocidade_correndo
	else:
		velocidade_alvo = velocidade_normal

	if direcao_horizontal == 0.0:
		derrapando = false
		velocity.x = move_toward(velocity.x, 0.0, desaceleracao * delta)
		return

	var invertendo_direcao: bool = (
		velocity.x != 0.0
		and sign(velocity.x) != direcao_horizontal
	)

	if (
		usar_derrapagem
		and is_on_floor()
		and invertendo_direcao
		and abs(velocity.x) >= velocidade_minima_derrapagem
	):
		derrapando = true
		velocity.x = move_toward(
			velocity.x,
			0.0,
			desaceleracao_derrapagem * delta
		)

		if debug_horizontal:
			debug_print("DERRAPAGEM: invertendo direção. Velocidade X = " + str(snapped(velocity.x, 0.1)))
		return

	derrapando = false

	if is_on_floor():
		var aceleracao_atual: float
		if is_running:
			aceleracao_atual = aceleracao_correndo
		else:
			aceleracao_atual = aceleracao

		velocity.x = move_toward(
			velocity.x,
			direcao_horizontal * velocidade_alvo,
			aceleracao_atual * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			direcao_horizontal * velocidade_alvo,
			aceleracao * controle_no_ar * delta
		)


# ============================================================
# GRAVIDADE
# ============================================================

func processar_gravidade(delta: float) -> void:
	if is_on_floor():
		return

	if velocity.y < 0.0:
		if (
			pulando
			and Input.is_action_pressed("pulo")
			and tempo_pulo < tempo_pulo_alto
		):
			velocity.y += gravidade_pulo_seguro * delta
		else:
			velocity.y += gravidade * gravidade_subindo * delta
	else:
		velocity.y += gravidade * gravidade_caindo * delta
		velocity.y = min(velocity.y, velocidade_maxima_queda)


# ============================================================
# PULO
# ============================================================

func processar_pulo() -> void:
	if Input.is_action_just_pressed("pulo"):
		jump_buffer_timer = tempo_buffer_pulo

		if debug_pulo:
			debug_print("PULO: botão pressionado -> Jump Buffer ativado.")

	if jump_buffer_timer <= 0.0:
		return

	if pode_pular():
		velocity.y = impulso_pulo
		pulando = true
		tempo_pulo = 0.0
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

		if debug_pulo:
			debug_print("PULO: EXECUTADO | impulso Y = " + str(impulso_pulo))


# ============================================================
# VERIFICAR PULO
# ============================================================

func pode_pular() -> bool:
	if is_on_floor():
		if debug_pulo:
			debug_print("PULO: permitido pelo chão.")
		return true

	if coyote_timer > 0.0:
		if debug_pulo:
			debug_print("PULO: permitido pelo Coyote Time.")
		return true

	if debug_pulo and Input.is_action_just_pressed("pulo"):
		debug_print("PULO: bloqueado - sem chão e Coyote Time expirado.")

	return false


# ============================================================
# CONTROLE DO PULO
# ============================================================

func _input(event: InputEvent) -> void:
	if not pulo_variavel:
		return

	if event.is_action_released("pulo"):
		if velocity.y < 0.0:
			velocity.y *= multiplicador_pulo_curto

		if debug_pulo:
			debug_print("PULO: botão solto -> pulo curto aplicado.")

		pulando = false


# ============================================================
# CORNER CORRECTION
# ============================================================

func aplicar_corner_correction() -> void:
	if not usar_corner_correction:
		return

	if corner_correction_apenas_subindo and velocity.y >= 0.0:
		return

	if direcao_horizontal == 0.0:
		return

	corner_raycast_esquerdo.force_raycast_update()
	corner_raycast_direito.force_raycast_update()

	var esquerdo_bateu: bool = corner_raycast_esquerdo.is_colliding()
	var direito_bateu: bool = corner_raycast_direito.is_colliding()

	if debug_corner_correction and (esquerdo_bateu or direito_bateu):
		debug_print("CORNER: RayCast detectou -> Esquerdo=" + str(esquerdo_bateu) + " | Direito=" + str(direito_bateu))

	if esquerdo_bateu and direito_bateu:
		if debug_corner_correction:
			debug_print("CORNER: os dois lados detectaram. Correção cancelada.")
		return

	var direcao_correcao: float = 0.0

	if direcao_horizontal > 0.0 and direito_bateu and not esquerdo_bateu:
		direcao_correcao = -1.0

	elif direcao_horizontal < 0.0 and esquerdo_bateu and not direito_bateu:
		direcao_correcao = 1.0

	if direcao_correcao == 0.0:
		return

	var posicao_original: Vector2 = global_position
	var transformacao_original: Transform2D = global_transform

	for i in range(1, corner_correction_tentativas + 1):
		var passo: float = (
			corner_correction_distancia
			* float(i)
			/ float(corner_correction_tentativas)
		)

		var deslocamento := Vector2(
			direcao_correcao * passo,
			0.0
		)

		if test_move(transformacao_original, deslocamento):
			continue

		global_position = posicao_original + deslocamento

		corner_raycast_esquerdo.force_raycast_update()
		corner_raycast_direito.force_raycast_update()

		var novo_esquerdo: bool = corner_raycast_esquerdo.is_colliding()
		var novo_direito: bool = corner_raycast_direito.is_colliding()

		if not novo_esquerdo and not novo_direito:
			if debug_corner_correction:
				if direcao_correcao < 0.0:
					debug_print("DIREITA CORRECT -> deslocou " + str(passo) + " px para a esquerda.")
				else:
					debug_print("ESQUERDA CORRECT -> deslocou " + str(passo) + " px para a direita.")
			return

	global_position = posicao_original

	if debug_corner_correction:
		debug_print("CORNER: detectou a quina, mas nenhuma posição segura foi encontrada.")


# ============================================================
# ATUALIZAR COYOTE TIME
# ============================================================

func atualizar_coyote() -> void:
	if is_on_floor():
		if coyote_timer <= 0.0 and debug_temporizadores:
			debug_print("COYOTE: timer iniciado -> " + str(tempo_coyote) + "s")
		coyote_timer = tempo_coyote


# ============================================================
# TEMPORIZADORES
# ============================================================

func atualizar_temporizadores(delta: float) -> void:
	var coyote_estava_ativo: bool = coyote_timer > 0.0
	var buffer_estava_ativo: bool = jump_buffer_timer > 0.0

	if coyote_timer > 0.0:
		coyote_timer -= delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if pulando:
		tempo_pulo += delta

	var coyote_ativo: bool = coyote_timer > 0.0
	var buffer_ativo: bool = jump_buffer_timer > 0.0

	if debug_temporizadores:
		if coyote_estava_ativo and not coyote_ativo:
			debug_print("COYOTE: expirou.")

		if buffer_estava_ativo and not buffer_ativo:
			debug_print("JUMP BUFFER: expirou.")

	debug_coyote_ativo_anterior = coyote_ativo
	debug_buffer_ativo_anterior = buffer_ativo
