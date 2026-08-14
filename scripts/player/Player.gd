extends CharacterBody2D
class_name Player1
# Define a classe Player associada ao CharacterBody2D

#=============== variaveis do player ==================
@export var velocidade_normal: float = 200.0
# Velocidade padrão de movimento
@export var velocidade_correndo: float = 350.0
# Velocidade quando o jogador estiver correndo (ex: segurando Shift)
@export var gravidade: float = 900.0
# Força da gravidade aplicada ao personagem quando estiver no ar
@export var impulso_pulo: float = -400.0
# Intensidade do pulo (valor negativo pois sobe no eixo Y)
#=========================================================

func _physics_process(delta):
	# Função chamada a cada frame de física (ideal para movimentação)

	mover()
	# Executa a movimentação horizontal

	velocity.y += gravidade * delta if not is_on_floor() else 0
	# Aplica gravidade se não estiver no chão

	pular()
	# Executa o pulo caso seja solicitado

	move_and_slide()
	# Move o personagem com colisões, respeitando o movimento horizontal e vertical


func mover():
	# Função responsável pela movimentação horizontal do personagem

	var direcao = Input.get_action_strength("andar_frente") - Input.get_action_strength("andar_traz")
	# Calcula a direção com base nas teclas pressionadas (ex: direita - esquerda)

	var velocidade_atual = velocidade_correndo if Input.is_action_pressed("correr") else velocidade_normal
	# Verifica se o jogador está correndo

	velocity.x = direcao * velocidade_atual
	# Aplica a velocidade horizontal


func pular():
	# Função responsável pelo pulo do personagem

	if Input.is_action_just_pressed("pulo") and is_on_floor():
		velocity.y = impulso_pulo
	# Permite pular apenas se estiver no chão e a tecla de pulo for pressionada
