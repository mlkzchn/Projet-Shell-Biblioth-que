#!/bin/sh

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$ROOT_DIR/data"
LIB="$ROOT_DIR/lib_functions.sh"

if [ ! -f "$LIB" ]; then
  echo "Fichier de fonctions introuvable : $LIB" >&2
  exit 1
fi

. "$LIB"

init_environment "$DATA_DIR"

if [ "$1" = "--backup-quotidien" ]; then
    backup_quotidien
    exit 0
fi

while true; do

  echo "============================================"
  echo "  Gestionnaire de Bibliothèque Personnelle"
  echo "============================================"
  echo "1) Gestion des livres"
  echo "2) Recherche et filtres"
  echo "3) Statistiques"
  echo "4) Gestion des emprunts"
  echo "5) Export (HTML)"
  echo "6) Sauvegarde manuelle"
  echo "q) Quitter"

  printf "Choix : " 
  read -r CHOICE 
  
  case "$CHOICE" in
    1) menu_livre ; pause_continue ;;
    2) menu_recherche ; pause_continue ;;
    3) menu_stats ; pause_continue ;;
    4) emprunt_menu ; pause_continue ;;
    5) printf "Nom du fichier de sortie: "; read -r out; export_html "$out"; pause_continue ;;
    6) backup_auto && echo "Sauvegarde effectuée." ; pause_continue ;;
    [qQ]) echo "à bientôt !" ; exit 0 ;;
    *) echo "Choix invalide." ; pause_continue ;;
  esac
done