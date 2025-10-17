#!/bin/bash

# Script de déploiement pour serveur Linux/Unix
# Usage: ./deploy.sh [--force] [--no-build]

set -e  # Arrêter le script en cas d'erreur

PROJECT_NAME="watermark"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Analyser les arguments
FORCE_REBUILD=false
NO_BUILD=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_REBUILD=true
                shift
                ;;
            --no-build)
                NO_BUILD=true
                shift
                ;;
            --help)
                echo "Usage: $0 [--force] [--no-build]"
                echo "  --force     Force la reconstruction même si des conteneurs existent"
                echo "  --no-build  Ignore la construction des images"
                exit 0
                ;;
            *)
                echo "Usage: $0 [--force] [--no-build]"
                echo "  --force     Force la reconstruction même si des conteneurs existent"
                echo "  --no-build  Ignore la construction des images"
                exit 1
                ;;
        esac
    done
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_prerequisites() {
    log "Vérification des prérequis..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log "ERROR: Docker n'est pas installé"
        exit 1
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log "ERROR: Docker Compose n'est pas installé"
        exit 1
    fi
    
    # Vérifier le fichier docker-compose.yml
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log "ERROR: Fichier $COMPOSE_FILE introuvable"
        exit 1
    fi
    
    # Vérifier le fichier .env
    if [[ ! -f "$ENV_FILE" ]]; then
        log "WARNING: Fichier $ENV_FILE introuvable, création d'un fichier par défaut"
        create_default_env
    fi
    
    log "Prérequis valides"
}

create_default_env() {
    cat > "$ENV_FILE" << EOF
# Environment Configuration
ENV=prod

# CORS Configuration
PROD_CORS_ORIGINS=https://img.floalz.fr

# Logging Configuration
LOGGING_LEVEL=INFO

# Port Configuration
HTTP_PORT=80
HTTPS_PORT=443
EOF
    log "Fichier $ENV_FILE créé avec les valeurs par défaut"
}

check_ssl_certificates() {
    log "Vérification des certificats SSL..."
    
    if [[ ! -d "nginx/ssl" ]]; then
        log "WARNING: Répertoire nginx/ssl introuvable, création..."
        mkdir -p "nginx/ssl"
    fi
    
    if [[ ! -f "nginx/ssl/cert.pem" ]]; then
        log "WARNING: Certificat SSL manquant dans nginx/ssl/cert.pem"
        log "WARNING: Vous devez placer votre certificat cert.pem dans nginx/ssl/"
        log "WARNING: L'application fonctionnera en HTTP uniquement sans certificat SSL"
    else
        log "Certificat SSL trouvé"
    fi
    
    if [[ ! -f "nginx/ssl/key.pem" ]]; then
        log "WARNING: Clé SSL manquante dans nginx/ssl/key.pem"
        log "WARNING: Vous devez placer votre clé key.pem dans nginx/ssl/"
        log "WARNING: L'application fonctionnera en HTTP uniquement sans clé SSL"
    else
        log "Clé SSL trouvée"
    fi
}

cleanup_old_containers() {
    log "Nettoyage des anciens conteneurs..."
    
    # Arrêter les conteneurs existants
    if docker-compose -f "$COMPOSE_FILE" ps -q &> /dev/null; then
        log "Arrêt des conteneurs existants..."
        docker-compose -f "$COMPOSE_FILE" down
    fi
    
    # Nettoyer les images inutilisées
    log "Nettoyage des images inutilisées..."
    docker image prune -f
}

build_images() {
    if [[ "$NO_BUILD" == "true" ]]; then
        log "Construction des images ignorée (--no-build)"
        return 0
    fi
    
    log "Construction des images Docker..."
    if ! docker-compose -f "$COMPOSE_FILE" build --no-cache; then
        log "ERROR: Échec de la construction des images"
        exit 1
    fi
}

start_services() {
    log "Démarrage des services..."
    if ! docker-compose -f "$COMPOSE_FILE" up -d; then
        log "ERROR: Échec du démarrage des services"
        exit 1
    fi
    
    # Attendre que les services soient prêts
    log "Attente du démarrage des services..."
    sleep 10
    
    # Vérifier le statut des services
    if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        log "ERROR: Échec du démarrage des services"
        exit 1
    fi
    
    log "Services démarrés avec succès"
}

check_services_status() {
    log "Vérification du statut des services..."
    
    # Attendre que les services soient prêts
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
            log "Tous les services sont démarrés"
            return 0
        fi
        
        ((attempt++))
        log "Tentative $attempt/$max_attempts - Attente du démarrage des services..."
        sleep 10
    done
    
    log "WARNING: Certains services ne sont pas encore démarrés"
    docker-compose -f "$COMPOSE_FILE" ps
}

show_deployment_info() {
    log "Déploiement terminé avec succès"
    echo
    echo "=== Informations de déploiement ==="
    echo "Services déployés:"
    docker-compose -f "$COMPOSE_FILE" ps
    echo
    echo "Logs des services:"
    echo "  docker-compose logs -f"
    echo
    echo "Arrêter les services:"
    echo "  docker-compose down"
    echo
    echo "Redémarrer un service:"
    echo "  docker-compose restart <service_name>"
    echo
}

# Fonction principale
main() {
    log "Début du déploiement de $PROJECT_NAME"
    
    check_prerequisites
    
    check_ssl_certificates
    
    if [[ "$FORCE_REBUILD" == "true" ]]; then
        cleanup_old_containers
    fi
    
    build_images
    
    start_services
    
    check_services_status
    
    show_deployment_info
    
    log "Déploiement terminé avec succès"
}

# Point d'entrée
parse_args "$@"
main