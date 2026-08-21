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

	# Posiciona os Rays automaticamente nos cantos da colisão.
	configurar_corner_rays()


# ============================================================
# CONFIGURAR RAYCASTS
# ============================================================

func configurar_corner_rays() -> void:
	# A configuração automática evita depender das posições antigas
	# que estavam salvas na cena.
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

	# Os dois Rays apontam verticalmente para cima.
	# A direção horizontal é determinada pelo lado que colidir.
	corner_raycast_esquerdo.target_position = Vector2(0.0, -corner_correction_altura)
	corner_raycast_direito.target_position = Vector2(0.0, -corner_correction_altura)

	corner_raycast_esquerdo.force_raycast_update()
	corner_raycast_direito.force_raycast_update()


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

	# Corner Correction é uma ajuda para o salto.
	# Não deve atuar durante a queda.
	if corner_correction_apenas_subindo and velocity.y >= 0.0:
		return

	# Sem movimento horizontal não há um lado preferencial.
	if direcao_horizontal == 0.0:
		return

	# Atualiza os dois sensores.
	corner_raycast_esquerdo.force_raycast_update()
	corner_raycast_direito.force_raycast_update()

	var esquerdo_bateu: bool = corner_raycast_esquerdo.is_colliding()
	var direito_bateu: bool = corner_raycast_direito.is_colliding()

	# Se os dois cantos estão presos no teto, não existe espaço lateral
	# suficiente para uma correção segura.
	if esquerdo_bateu and direito_bateu:
		return

	# A correção é feita para o lado livre.
	var direcao_correcao: float = 0.0

	# Indo para a direita e o canto direito bateu:
	# desloca alguns pixels para a esquerda.
	if direcao_horizontal > 0.0 and direito_bateu and not esquerdo_bateu:
		direcao_correcao = -1.0

	# Indo para a esquerda e o canto esquerdo bateu:
	# desloca alguns pixels para a direita.
	elif direcao_horizontal < 0.0 and esquerdo_bateu and not direito_bateu:
		direcao_correcao = 1.0

	if direcao_correcao == 0.0:
		return

	# Guarda a posição original para poder testar cada tentativa.
	var posicao_original: Vector2 = global_position
	var transformacao_original: Transform2D = global_transform

	# Procura a menor correção que tira o canto da plataforma.
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

		# Não corrige para dentro de outro obstáculo.
		if test_move(transformacao_original, deslocamento):
			continue

		# Testa a posição candidata com os RayCast2D.
		global_position = posicao_original + deslocamento

		corner_raycast_esquerdo.force_raycast_update()
		corner_raycast_direito.force_raycast_update()

		var novo_esquerdo: bool = corner_raycast_esquerdo.is_colliding()
		var novo_direito: bool = corner_raycast_direito.is_colliding()

		# O lado que estava preso ficou livre.
		if not novo_esquerdo and not novo_direito:
			return

	# Nenhuma posição testada foi segura.
	global_position = posicao_original


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
