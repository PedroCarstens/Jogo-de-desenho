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
# Os dois RayCast2D ficam nos cantos superiores do Player.
# Eles detectam a quina durante a subida.
# Depois test_move() verifica se existe espaço para subir.
# ============================================================

@export_category("Corner Correction")

# Ativa ou desativa a correção de quina.
@export var usar_corner_correction: bool = true

# Altura máxima que o personagem pode ser corrigido.
@export_range(0.0, 16.0, 0.5)
var corner_correction_altura: float = 8.0

# Distância horizontal usada no teste de passagem.
@export_range(0.0, 16.0, 0.5)
var corner_correction_distancia: float = 6.0

# Quantidade de tentativas para encontrar espaço.
@export_range(1, 8, 1)
var corner_correction_tentativas: int = 4

# Se ativado, a correção só acontece durante a subida.
@export var corner_correction_apenas_subindo: bool = true

# Os nomes correspondem exatamente aos RayCast2D da cena atual.
@onready var corner_raycast_direito: RayCast2D = $"RayCast direito"
@onready var corner_raycast_esquerdo: RayCast2D = $"RayCast esquerdo direito2"


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
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:
	# Garante que os dois sensores estejam ativos.
	corner_raycast_direito.enabled = true
	corner_raycast_esquerdo.enabled = true


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


# ============================================================
# MOVIMENTO HORIZONTAL
# ============================================================

func processar_movimento_horizontal(delta: float) -> void:
	direcao_horizontal = Input.get_axis("andar_traz", "andar_frente")

	if permitir_corrida:
		is_running = Input.is_action_pressed("correr")
	else:
		is_running = false

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

	if jump_buffer_timer <= 0.0:
		return

	if pode_pular():
		velocity.y = impulso_pulo
		pulando = true
		tempo_pulo = 0.0
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


# ============================================================
# VERIFICAR PULO
# ============================================================

func pode_pular() -> bool:
	if is_on_floor():
		return true

	if coyote_timer > 0.0:
		return true

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
		pulando = false


# ============================================================
# CORNER CORRECTION
# ============================================================

func aplicar_corner_correction() -> void:
	# Não executa se estiver desativado.
	if not usar_corner_correction:
		return

	# Corner Correction funciona durante a subida.
	if corner_correction_apenas_subindo and velocity.y >= 0.0:
		return

	# Sem movimento horizontal não existe direção para corrigir.
	if direcao_horizontal == 0.0:
		return

	# Usa somente o RayCast correspondente ao lado do movimento.
	var raycast: RayCast2D

	if direcao_horizontal > 0.0:
		raycast = corner_raycast_direito
	else:
		raycast = corner_raycast_esquerdo

	raycast.force_raycast_update()

	# Não há obstáculo no canto.
	if not raycast.is_colliding():
		return

	# Testa pequenas alturas até encontrar uma posição livre.
	for i in range(1, corner_correction_tentativas + 1):
		var passo: float = (
			corner_correction_altura
			* float(i)
			/ float(corner_correction_tentativas)
		)

		var transformacao_teste := global_transform
		transformacao_teste.origin.y -= passo

		# Verifica se o corpo inteiro consegue avançar
		# depois de subir essa quantidade.
		var deslocamento := Vector2(
			direcao_horizontal * corner_correction_distancia,
			0.0
		)

		if not test_move(transformacao_teste, deslocamento):
			global_position.y -= passo
			return


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
	if coyote_timer > 0.0:
		coyote_timer -= delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if pulando:
		tempo_pulo += delta
