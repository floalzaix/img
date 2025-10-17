@echo off
setlocal enabledelayedexpansion

REM Script de déploiement pour serveur Windows
REM Usage: deploy.bat [--force] [--no-build]

set "PROJECT_NAME=watermark"
set "COMPOSE_FILE=docker-compose.yml"
set "ENV_FILE=.env"

REM Analyser les arguments
set "FORCE_REBUILD=false"
set "NO_BUILD=false"

:parse_args
if "%~1"=="" goto :main
if "%~1"=="--force" (
    set "FORCE_REBUILD=true"
    shift
    goto :parse_args
)
if "%~1"=="--no-build" (
    set "NO_BUILD=true"
    shift
    goto :parse_args
)
if "%~1"=="--help" (
    echo Usage: %0 [--force] [--no-build]
    echo   --force     Force la reconstruction meme si des conteneurs existent
    echo   --no-build  Ignore la construction des images
    exit /b 0
)
echo Usage: %0 [--force] [--no-build]
echo   --force     Force la reconstruction meme si des conteneurs existent
echo   --no-build  Ignore la construction des images
exit /b 1

:main
echo [%date% %time%] Debut du deploiement de %PROJECT_NAME%

call :check_prerequisites
if errorlevel 1 exit /b 1

call :check_ssl_certificates

if "%FORCE_REBUILD%"=="true" (
    call :cleanup_old_containers
    if errorlevel 1 exit /b 1
)

call :build_images
if errorlevel 1 exit /b 1

call :start_services
if errorlevel 1 exit /b 1

call :check_services_status

call :show_deployment_info

echo [%date% %time%] Deploiement termine avec succes
exit /b 0

:check_prerequisites
echo [%date% %time%] Verification des prerequis...

REM Verifier Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] ERROR: Docker n'est pas installe
    exit /b 1
)

REM Verifier Docker Compose
docker-compose --version >nul 2>&1
if errorlevel 1 (
    docker compose version >nul 2>&1
    if errorlevel 1 (
        echo [%date% %time%] ERROR: Docker Compose n'est pas installe
        exit /b 1
    )
)

REM Verifier le fichier docker-compose.yml
if not exist "%COMPOSE_FILE%" (
    echo [%date% %time%] ERROR: Fichier %COMPOSE_FILE% introuvable
    exit /b 1
)

REM Verifier le fichier .env
if not exist "%ENV_FILE%" (
    echo [%date% %time%] WARNING: Fichier %ENV_FILE% introuvable, creation d'un fichier par defaut
    call :create_default_env
)

echo [%date% %time%] Prerequis valides
exit /b 0

:create_default_env
(
echo # Environment Configuration
echo ENV=prod
echo.
echo # CORS Configuration
echo PROD_CORS_ORIGINS=https://img.floalz.fr
echo.
echo # Logging Configuration
echo LOGGING_LEVEL=INFO
echo.
echo # Port Configuration
echo HTTP_PORT=80
echo HTTPS_PORT=443
) > "%ENV_FILE%"
echo [%date% %time%] Fichier %ENV_FILE% cree avec les valeurs par defaut
exit /b 0

:check_ssl_certificates
echo [%date% %time%] Verification des certificats SSL...

if not exist "nginx\ssl" (
    echo [%date% %time%] WARNING: Repertoire nginx\ssl introuvable, creation...
    mkdir "nginx\ssl"
)

if not exist "nginx\ssl\cert.pem" (
    echo [%date% %time%] WARNING: Certificat SSL manquant dans nginx\ssl\cert.pem
    echo [%date% %time%] WARNING: Vous devez placer votre certificat cert.pem dans nginx\ssl\
    echo [%date% %time%] WARNING: L'application fonctionnera en HTTP uniquement sans certificat SSL
) else (
    echo [%date% %time%] Certificat SSL trouve
)

if not exist "nginx\ssl\key.pem" (
    echo [%date% %time%] WARNING: Cle SSL manquante dans nginx\ssl\key.pem
    echo [%date% %time%] WARNING: Vous devez placer votre cle key.pem dans nginx\ssl\
    echo [%date% %time%] WARNING: L'application fonctionnera en HTTP uniquement sans cle SSL
) else (
    echo [%date% %time%] Cle SSL trouvee
)
exit /b 0

:cleanup_old_containers
echo [%date% %time%] Nettoyage des anciens conteneurs...

REM Arreter les conteneurs existants
docker-compose -f "%COMPOSE_FILE%" ps -q >nul 2>&1
if not errorlevel 1 (
    echo [%date% %time%] Arret des conteneurs existants...
    docker-compose -f "%COMPOSE_FILE%" down
)

REM Nettoyer les images inutilisees
echo [%date% %time%] Nettoyage des images inutilisees...
docker image prune -f
exit /b 0

:build_images
if "%NO_BUILD%"=="true" (
    echo [%date% %time%] Construction des images ignoree (--no-build)
    exit /b 0
)

echo [%date% %time%] Construction des images Docker...
docker-compose -f "%COMPOSE_FILE%" build --no-cache
if errorlevel 1 (
    echo [%date% %time%] ERROR: Echec de la construction des images
    exit /b 1
)
exit /b 0

:start_services
echo [%date% %time%] Demarrage des services...
docker-compose -f "%COMPOSE_FILE%" up -d
if errorlevel 1 (
    echo [%date% %time%] ERROR: Echec du demarrage des services
    exit /b 1
)

REM Attendre que les services soient prets
echo [%date% %time%] Attente du demarrage des services...
timeout /t 10 /nobreak >nul

REM Verifier le statut des services
docker-compose -f "%COMPOSE_FILE%" ps | findstr "Up" >nul
if errorlevel 1 (
    echo [%date% %time%] ERROR: Echec du demarrage des services
    exit /b 1
)

echo [%date% %time%] Services demarres avec succes
exit /b 0

:check_services_status
echo [%date% %time%] Verification du statut des services...

REM Attendre que les services soient prets
set "max_attempts=30"
set "attempt=0"

:status_check_loop
if %attempt% geq %max_attempts% (
    echo [%date% %time%] WARNING: Certains services ne sont pas encore demarres
    docker-compose -f "%COMPOSE_FILE%" ps
    exit /b 0
)

docker-compose -f "%COMPOSE_FILE%" ps | findstr "Up" >nul
if not errorlevel 1 (
    echo [%date% %time%] Tous les services sont demarres
    exit /b 0
)

set /a attempt+=1
echo [%date% %time%] Tentative %attempt%/%max_attempts% - Attente du demarrage des services...
timeout /t 10 /nobreak >nul
goto :status_check_loop

:show_deployment_info
echo [%date% %time%] Deploiement termine avec succes
echo.
echo === Informations de deploiement ===
echo Services deployes:
docker-compose -f "%COMPOSE_FILE%" ps
echo.
echo Logs des services:
echo   docker-compose logs -f
echo.
echo Arreter les services:
echo   docker-compose down
echo.
echo Redemarrer un service:
echo   docker-compose restart ^<service_name^>
echo.
exit /b 0
