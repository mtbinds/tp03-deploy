#!/usr/bin/env bash
# pipeline.sh - Pipeline CI/CD NetOps local
# Usage :
#   ./pipeline.sh          -> lint + dry-run (CI mode)
#   ./pipeline.sh deploy   -> lint + dry-run + deploy

set -euo pipefail   # arrêt immédiat sur erreur, variable non définie, pipe cassé

# ─────────────────── Couleurs ──────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'          # Reset couleur (No Color)

step() { echo -e "\n${BLUE}>> $1${NC}"; }       # En-tête de stage (bleu)
ok()   { echo -e "${GREEN}[OK] $1${NC}"; }         # Succès (vert)
fail() { echo -e "${RED}[KO] $1${NC}"; exit 1; }   # Echec + arrêt immédiat (rouge)
warn() { echo -e "${YELLOW}[!] $1${NC}"; }        # Avertissement (jaune)

DEPLOY=${1:-""}    # Premier argument : "deploy" pour activer le stage 3

# ─────────────────── Stage 1 : Lint ────────────────────────
step "Stage 1/3 - Lint YAML (yamllint)"
yamllint . || fail "yamllint a détecté des erreurs"
# "||" : opérateur OU - si yamllint retourne code != 0, fail() est appelé
ok "yamllint : aucune erreur"

step "Stage 1/3 - Lint Ansible (ansible-lint)"
ansible-lint playbooks/ || fail "ansible-lint a détecté des violations"
ok "ansible-lint : aucune violation"

# ─────────────────── Stage 2 : Dry-run ─────────────────────
step "Stage 2/3 - Dry-run (--check --diff)"
ansible-playbook --check --diff playbooks/site.yml \
  || fail "Le dry-run a échoué - déploiement annulé"
ok "Dry-run : aucun problème détecté"

# ─────────────────── Stage 3 : Deploy ──────────────────────
if [[ "$DEPLOY" == "deploy" ]]; then      # [[ ]] : test bash (plus fiable que [ ])
  step "Stage 3/3 - Déploiement réel"
  warn "Application des changements en cours..."
  ansible-playbook playbooks/site.yml \
    || fail "Le déploiement a échoué"
  ok "Déploiement terminé avec succès"
else
  warn "Stage 3/3 - Déploiement ignoré (mode CI)"
  echo "  -> Pour déployer : ./pipeline.sh deploy"
fi

echo -e "\n${GREEN}Pipeline terminé avec succès.${NC}"
