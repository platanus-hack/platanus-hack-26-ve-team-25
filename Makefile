# Atajos para correr el proyecto desde la raíz del repo. `make` sin nada muestra la ayuda.

APP := app
WEB := web
# El número de emergencia vive en app/config/local.json, que no se sube (el repo es público).
CONFIG := $(if $(wildcard $(APP)/config/local.json),--dart-define-from-file=config/local.json,)
# Si bun no está instalado, se usa la versión del proyecto con npx.
BUN ?= $(shell command -v bun 2>/dev/null || echo "npx -y bun@1.3.14")

.DEFAULT_GOAL := ayuda
.PHONY: ayuda devices deps run run-demo debug profile release test analyze format \
	build-apk build-apk-debug build-appbundle install clean \
	web-deps web-dev web-test web-lint web-build

ayuda: ## Muestra estos comandos
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# --- App de la casa (Flutter) ---------------------------------------------------------------

devices: ## Lista los teléfonos conectados
	flutter devices

deps: ## Baja las dependencias de la app
	cd $(APP) && flutter pub get

run: deps ## Corre la app en el teléfono conectado (r recarga, q sale)
	cd $(APP) && flutter run $(CONFIG)

run-demo: deps ## Corre la app con la cuenta regresiva de 15 s del demo
	cd $(APP) && flutter run $(CONFIG) --dart-define=DEMO=true

debug: run ## Igual que run: modo debug con recarga en caliente

profile: deps ## Corre la app en modo profile, para medir rendimiento en el teléfono
	cd $(APP) && flutter run $(CONFIG) --profile

release: deps ## Corre la app en modo release, como la vería el usuario
	cd $(APP) && flutter run $(CONFIG) --release

test: deps ## Corre las pruebas de la app
	cd $(APP) && flutter test

analyze: deps ## Revisa el código de la app
	cd $(APP) && flutter analyze

format: ## Formatea el código de la app
	cd $(APP) && dart format lib test

build-apk-debug: deps ## Arma el APK de debug
	cd $(APP) && flutter build apk $(CONFIG) --debug

build-apk: deps ## Arma el APK de release, para instalar a mano
	cd $(APP) && flutter build apk $(CONFIG) --release

build-appbundle: deps ## Arma el App Bundle (.aab) de release, para Google Play
	cd $(APP) && flutter build appbundle $(CONFIG) --release

install: build-apk ## Instala el APK de release en el teléfono conectado
	cd $(APP) && flutter install --release

clean: ## Borra lo compilado de la app
	cd $(APP) && flutter clean

# --- Web de la familia (Next.js) ------------------------------------------------------------

web-deps: ## Baja las dependencias de la web
	cd $(WEB) && $(BUN) install

web-dev: web-deps ## Corre la web en http://localhost:3000
	cd $(WEB) && $(BUN) run dev

web-test: web-deps ## Corre las pruebas de la web
	cd $(WEB) && $(BUN) test

web-lint: web-deps ## Revisa el código de la web
	cd $(WEB) && $(BUN) run lint

web-build: web-deps ## Arma la web para producción
	cd $(WEB) && $(BUN) run build
