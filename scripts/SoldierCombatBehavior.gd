class_name SoldierCombatBehavior
extends Node3D
## Comportamento de combate reutilizável para os soldados de fundo (militares
## de um lado, revolucionários do outro). Controla autonomamente o ciclo de
## disparos (muzzle flash) e o fade de opacidade ("nevoeiro/fumaça").
## Anexar no nó raiz Node3D da cena do soldado, com um filho Sprite3D e um
## filho OmniLight3D (MuzzleFlash) posicionado na ponta da arma.

@export_group("Disparos (Muzzle Flash)")
## Intervalo mínimo entre disparos (segundos).
@export var min_interval_disparo: float = 0.5
## Intervalo máximo entre disparos (segundos).
@export var max_interval_disparo: float = 2.5
## Cor do clarão do disparo.
@export var cor_muzzle: Color = Color(1.0, 0.85, 0.5)
## Intensidade mínima do clarão.
@export var intensidade_min: float = 4.0
## Intensidade máxima do clarão.
@export var intensidade_max: float = 8.0

@export_group("Aparição (Fade / Nevoeiro)")
## Duração mínima de cada transição de opacidade.
@export var duracao_fade_min: float = 1.0
## Duração máxima de cada transição de opacidade.
@export var duracao_fade_max: float = 3.0
## Alpha mínimo (parcialmente encoberto pela fumaça).
@export var alpha_min: float = 0.2
## Alpha máximo (totalmente visível).
@export var alpha_max: float = 1.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var muzzle_flash: OmniLight3D = $MuzzleFlash

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	if muzzle_flash:
		muzzle_flash.light_color = cor_muzzle
		muzzle_flash.light_energy = 0.0

	# Inicia os ciclos de forma assíncrona/concorrente para evitar picos
	# de processamento; cada instância tem seu próprio rng, então nenhum
	# soldado dispara ou some sincronizado.
	_iniciar_ciclo_disparos()
	#_iniciar_ciclo_aparição()

# --- 1. Lógica de Disparos Aleatórios (Muzzle Flash) ---
func _iniciar_ciclo_disparos() -> void:
	while is_inside_tree():
		var espera: float = rng.randf_range(min_interval_disparo, max_interval_disparo)
		await get_tree().create_timer(espera).timeout

		if muzzle_flash:
			muzzle_flash.light_energy = rng.randf_range(intensidade_min, intensidade_max)
			await get_tree().create_timer(rng.randf_range(0.05, 0.15)).timeout
			muzzle_flash.light_energy = 0.0

# --- 2. Lógica de "Nevoeiro e Aparição" (Fade via Tween) ---
func _iniciar_ciclo_aparição() -> void:
	while is_inside_tree():
		var duracao: float = rng.randf_range(duracao_fade_min, duracao_fade_max)
		var alvo_alpha: float = rng.randf_range(alpha_min, alpha_max)

		var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "modulate:a", alvo_alpha, duracao)
		await tween.finished
