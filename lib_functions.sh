#!/bin/sh

set -e

init_environment() {

  base_dir="${1:-./data}" 
  mkdir -p "$base_dir"
  mkdir -p "$base_dir/backups"

  LIVRES_FILE="$base_dir/livres.txt"
  EMPRUNTS_FILE="$base_dir/emprunts.txt"
  HISTORY_FILE="$base_dir/historique.txt"
  BACKUPS_DIR="$base_dir/backups"
}

file_livres() { echo "$LIVRES_FILE"; }
file_emprunts() { echo "$EMPRUNTS_FILE"; }
file_historique() { echo "$HISTORY_FILE"; }
file_backups_dir() { echo "$BACKUPS_DIR"; }

pause_continue() {
  printf "Continuez en appuyant sur entrée\n"
  read -r _
}

gen_id() {
  f=$(file_livres)

  awk -F'|' 'BEGIN{max=0} {if($1+0>max) max=$1+0} END{printf "%03d", max+1}' "$f" #id sur 3 chiffres (à changer si on a plus de 1000 livres)
}

annee_valide() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

backup_auto() {
  base=$(file_backups_dir)

  ts=$(date +%Y%m%d_%H%M%S) 
  cp "$(file_livres)" "$base/livres_$ts.txt" 2>/dev/null || true
  cp "$(file_emprunts)" "$base/emprunts_$ts.txt" 2>/dev/null || true
  cp "$(file_historique)" "$base/historique_$ts.txt" 2>/dev/null || true
}


lister_livres() {
    printf '\n------------------------------------------------------------\n\n'
    livres_file=$(file_livres)
    nb_par_page=5

    if [ ! -s "$livres_file" ]; then
        echo "Aucun livre enregistré."
        printf '\n------------------------------------------------------------\n\n'
        return 0
    fi

    total=$(wc -l < "$livres_file" | tr -d ' ')

    
    pages_temp1=$(expr "$total" + "$nb_par_page" 2>/dev/null) || true
    pages_temp2=$(expr "$pages_temp1" - 1 2>/dev/null) || true
    pages=$(expr "$pages_temp2" / "$nb_par_page" 2>/dev/null) || true
    
    [ -z "$pages" ] && pages=1 
    [ "$pages" -lt 1 ] && pages=1

    page=1

    while :; do
        
        echo "Page $page / $pages"

        start_temp1=$(expr "$page" - 1 2>/dev/null) || true
        start=$(expr "$start_temp1" \* "$nb_par_page" 2>/dev/null) || true
        start=$(expr "$start" + 1 2>/dev/null) || true
        
        end=$(expr "$page" \* "$nb_par_page" 2>/dev/null) || true

        awk -F'|' -v start="$start" -v end="$end" '
        NR >= start && NR <= end {
            printf "%s | %s | %s | %s | %s | %s\n", $1, $2, $3, $4, $5, $6
        }' "$livres_file"

        echo
        echo "n: suivant, p: précédent, q: quitter"
        printf "Choix: "

        if ! IFS= read -r ch; then
            ch="q"
        fi

        case "$ch" in
            [nN])
                if [ "$page" -lt "$pages" ]; then
                    page=$(expr "$page" + 1 2>/dev/null) || true
                else
                    echo "Dernière page."
                fi
                ;;
            [pP])
                if [ "$page" -gt 1 ]; then
                    page=$(expr "$page" - 1 2>/dev/null) || true
                else
                    echo "Première page."
                fi
                ;;
            [qQ])
                break
                ;;
            *)
                echo "Choix invalide."
                ;;
        esac
    done
    printf '\n------------------------------------------------------------\n\n'
}





ajouter_livre() {
  printf '\n------------------------------------------------------------\n\n'
  livres_file=$(file_livres)
  printf "Ajouter un livre — remplissez les champs (q pour quitter à tout moment) :\n"

  printf "Titre: "
  read -r titre
  case "$titre" in [qQ]) echo "Abandon de l'ajout." ; return ;; esac

  printf "Auteur: "
  read -r auteur
  case "$auteur" in [qQ]) echo "Abandon de l'ajout." ; return ;; esac

  while :; do
    printf "Année: "
    read -r annee
    case "$annee" in [qQ]) echo "Abandon de l'ajout." ; return ;; esac
    annee_valide "$annee" && break || echo "Année invalide."
  done

  printf "Genre: "
  read -r genre
  case "$genre" in [qQ]) echo "Abandon de l'ajout." ; return ;; esac

  id=$(gen_id)
  printf "%s|%s|%s|%s|%s|disponible\n" "$id" "$titre" "$auteur" "$annee" "$genre" >> "$livres_file"

  backup_auto
  echo "Livre ajouté avec ID $id"
  printf '\n------------------------------------------------------------\n\n'
}

modifier_livre() {
    printf '\n------------------------------------------------------------\n\n'
    livres_file=$(file_livres)
    id=""
    while :; do
        printf "ID du livre à modifier (q pour quitter): "
        read -r id
        case "$id" in [qQ]) echo "Abandon de la modification." ; return ;; esac
        grep -E "^${id}\|" "$livres_file" >/dev/null 2>&1 && break || echo "ID introuvable. Réessayez."
    done

    old_title=$(awk -F'|' -v id="$id" '$1==id {print $2}' "$livres_file")
    old_auteur=$(awk -F'|' -v id="$id" '$1==id {print $3}' "$livres_file")
    old_annee=$(awk -F'|' -v id="$id" '$1==id {print $4}' "$livres_file")
    old_genre=$(awk -F'|' -v id="$id" '$1==id {print $5}' "$livres_file")
    old_statut=$(awk -F'|' -v id="$id" '$1==id {print $6}' "$livres_file")

    echo "Informations actuelles du livre :"
    echo "ID     : $id"
    echo "Titre  : $old_title"
    echo "Auteur : $old_auteur"
    echo "Année  : $old_annee"
    echo "Genre  : $old_genre"
    echo "Statut : $old_statut"
    echo "----------------------------------"

    
    printf "Nouveau titre (laisser vide pour garder: %s): " "$old_title"
    read -r title_input
    case "$title_input" in [qQ]) echo "Abandon de la modification." ; return ;; esac
    title=${title_input:-$old_title}

    printf "Nouvel auteur (laisser vide pour garder: %s): " "$old_auteur"
    read -r auteur_input
    case "$auteur_input" in [qQ]) echo "Abandon de la modification." ; return ;; esac
    auteur=${auteur_input:-$old_auteur}

    annee="" 
    while :; do
        printf "Nouvelle année (laisser vide pour garder: %s): " "$old_annee"
        read -r annee_input
        case "$annee_input" in [qQ]) echo "Abandon de la modification." ; return ;; esac
        if [ -z "$annee_input" ]; then
            annee="$old_annee"
            break
        fi
        annee_valide "$annee_input" && annee="$annee_input" && break || echo "Année invalide."
    done

    printf "Nouveau genre (laisser vide pour garder: %s): " "$old_genre"
    read -r genre_input
    case "$genre_input" in [qQ]) echo "Abandon de la modification." ; return ;; esac
    genre=${genre_input:-$old_genre}

    awk -F'|' -v id="$id" -v t="$title" -v a="$auteur" -v y="$annee" -v g="$genre" \
        'BEGIN{OFS="|"} $1==id{$2=t;$3=a;$4=y;$5=g} {print}' "$livres_file" > "$livres_file.tmp"
    mv "$livres_file.tmp" "$livres_file"

    backup_auto
    echo "Livre $id modifié."
    printf '\n------------------------------------------------------------\n\n'
}


supprimer_livre() {
  printf '\n------------------------------------------------------------\n\n'
  livres_file=$(file_livres)
  while :; do
    printf "ID du livre à supprimer (q pour quitter): "
    read -r id
    case "$id" in [qQ]) echo "Abandon de la suppression." ; return ;; esac
    grep -E "^${id}\|" "$livres_file" >/dev/null 2>&1 && break || echo "ID introuvable."
  done

  grep -v -E "^${id}\|" "$livres_file" > "$livres_file.tmp"
  mv "$livres_file.tmp" "$livres_file"

  backup_auto
  echo "Livre $id supprimé."
  printf '\n------------------------------------------------------------\n\n'
}


menu_livre() {
  printf '\n------------------------------------------------------------\n\n'
  while :; do
    
    echo "=== Gestion des livres ==="
    echo "1) Ajoutez un livre"
    echo "2) Supprimer un livre "
    echo "3) Modifier un livre"
    echo "4) Lister les livres"
    echo "q) Retour"
    printf "Choix: "
    read -r c
    case "$c" in
      1) ajouter_livre ; pause_continue ;;
      2) supprimer_livre ; pause_continue ;;
      3) modifier_livre ; pause_continue ;;
      4) lister_livres ; pause_continue ;;
      [qQ]) break ;;
      *) echo "Choix invalide." ; pause_continue ;;
    esac
  done
}



chercher_titre() {
  term="$1"
  livres_file=$(file_livres)
  term_lc=$(printf '%s\n' "$term" | awk '{print tolower($0)}')
  awk -F'|' -v term="$term_lc" '{
    line_lc = tolower($2)
    if (index(line_lc, term)) printf "%s | %s | %s | %s | %s | %s\n",$1,$2,$3,$4,$5,$6
  }' "$livres_file" || echo "Aucun résultat."
}


chercher_auteur() {
  auteur="$1"
  livres_file=$(file_livres)
  auteur_lc=$(printf '%s\n' "$auteur" | awk '{print tolower($0)}')
  awk -F'|' -v a="$auteur_lc" '{
    line_lc = tolower($3)
    if (index(line_lc, a)) printf "%s | %s | %s | %s | %s | %s\n",$1,$2,$3,$4,$5,$6
  }' "$livres_file" || echo "Aucun résultat."
}

afficher_genre(){
  livres_file=$(file_livres)

  printf "\nGenres disponibles :\n"
  awk -F '|' '{print $5}' "$livres_file" | sort -u | sed '/^$/d'
  printf "\n"
}

chercher_genre() {
  genre="$1"
  livres_file=$(file_livres)
  genre_lc=$(printf '%s\n' "$genre" | awk '{print tolower($0)}')

  awk -F '|' -v g="$genre_lc" '
    {
      lc = tolower($5)
      if (index(lc, g))
        printf "%s | %s | %s | %s | %s | %s\n",$1,$2,$3,$4,$5,$6
    }
  ' "$livres_file"
}

chercher_annee() {
  y1="$1"
  y2="$2"
  livres_file=$(file_livres)
  awk -F'|' -v a="$y1" -v b="$y2" '($4+0>=a && $4+0<=b){printf "%s | %s | %s | %s | %s | %s\n",$1,$2,$3,$4,$5,$6}' "$livres_file" || echo "Aucun résultat."
}

recherche_avancee() {
  livres_file=$(file_livres)
  echo "Entrez critères (laisser vide pour ignorer):"
  printf "Titre (partiel): "; read -r t
  printf "Auteur: "; read -r a
  printf "Genre: "; read -r g
  printf "Année début: "; read -r y1
  printf "Année fin: "; read -r y2

  t_lc=$(printf '%s\n' "$t" | awk '{print tolower($0)}')
  a_lc=$(printf '%s\n' "$a" | awk '{print tolower($0)}')
  g_lc=$(printf '%s\n' "$g" | awk '{print tolower($0)}')

  awk -F'|' -v t="$t_lc" -v a="$a_lc" -v g="$g_lc" -v y1="$y1" -v y2="$y2" '{
    ok=1
    if (t!="" && index(tolower($2), t)==0) ok=0
    if (a!="" && index(tolower($3), a)==0) ok=0
    if (g!="" && index(tolower($5), g)==0) ok=0
    if (y1!="" && $4+0 < y1+0) ok=0
    if (y2!="" && $4+0 > y2+0) ok=0
    if (ok) printf "%s | %s | %s | %s | %s | %s\n",$1,$2,$3,$4,$5,$6
  }' "$livres_file" || echo "Aucun résultat."
}


stats_total() {
  livres_file=$(file_livres)
  echo "Total: $(awk 'END{print NR}' "$livres_file") livres"
}

stats_genre_ascii() {
  livres_file=$(file_livres)

  awk -F'|' '
  {
    genre = $5;
    
    count[genre]++;
    
    if (titles[genre] == "") {
      titles[genre] = $2
    } else {
      titles[genre] = titles[genre] "; " $2
    }
  } 
  END {
    for (g in count) {
      print count[g] "|" g "|" titles[g]
    }
  }' "$livres_file" | sort -t'|' -nr | while IFS='|' read -r cnt genre titles_list; do
    
    
    bar=""
    i=0
    while [ "$(expr "$i" '<' "$cnt")" -eq 1 ]; do
      bar="${bar}#"
      i=$(expr "$i" + 1)
    done
    
    printf "%-20s | %3d %s\n" "$genre" "$cnt" "$bar"
    
    
    if [ -n "$titles_list" ]; then
        printf '%s\n' "$titles_list" | sed 's/; /\n/g' | sed 's/^/  - /' 
        echo
    fi
    
  done
}

top_auteurs() {
  printf '\n------------------------------------------------------------\n\n'
  livres_file=$(file_livres)
  awk -F'|' '{count[$3]++} END{for(a in count) print count[a] "|" a}' "$livres_file" | sort -t'|' -nr | head -5 | awk -F'|' '{printf "%s - %s livres\n",$2,$1}'
  printf '\n------------------------------------------------------------\n\n'
}

livre_par_decenie() {
  printf '\n------------------------------------------------------------\n\n'
  livres_file=$(file_livres)
  awk -F'|' '
  {
    dec = int($4/10) * 10;
    count[dec]++;
    
    if (titles[dec] == "") {
      titles[dec] = $2
    } else {
      titles[dec] = titles[dec] "; " $2
    }
  } 
  END {
    for (d in count) {
      print d ":" count[d] ":" titles[d]
    }
  }' "$livres_file" | sort -t: -k1,1n | while IFS=':' read -r dec cnt titles_list; do
    
    dec_fin=$(expr "$dec" + 9)
    echo "=== Décennie ${dec}-${dec_fin} : $cnt livres ==="
    printf '%s\n' "$titles_list" | sed 's/; /\n/g' | sed 's/^/  - /' 
    echo
  done
  
  printf '\n------------------------------------------------------------\n\n'
}

export_html() {
  out="$1"
  livres_file=$(file_livres)
  html_file="${out}.html"

  echo "<!DOCTYPE html>
<html lang='fr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>Bibliothèque – Export</title>

<style>
  body {
      font-family: 'Segoe UI', Tahoma, Arial, sans-serif; 
      background: #eef1f6;
      margin: 0;
      padding: 30px 10px;
  }

  .container {
      max-width: 1200px;
      margin: auto;
  }

  h1 {
      text-align: center;
      margin-bottom: 35px;
      color: #1f3a68;
      font-size: 2.5em;
  }

  .card {
      background: white;
      padding: 0; 
      border-radius: 12px;
      box-shadow: 0 8px 20px rgba(0,0,0,0.1); 
      overflow: hidden; 
  }

  table {
      width: 100%;
      border-collapse: collapse;
      margin: 0;
  }

  thead {
      background: #1f3a68; 
      color: white;
      font-weight: 600;
      text-align: left;
  }

  th, td {
      padding: 15px 20px;
      font-size: 14px;
    border-bottom: 1px solid #e0e6f0;
  }
  
  tbody tr:last-child td {
      border-bottom: none;
  }

  tr:nth-child(even) {
      background: #f7f9fc;
  }

  tr:hover {
      background: #e0f0ff; 
  }
  
  .statut-disponible {
      background-color: #e9ffe6; 
      color: #338600;
      font-weight: bold;
      border-radius: 4px;
      padding: 4px 8px;
      display: inline-block;
  }

  .statut-emprunte {
      background-color: #fff1f0;
      color: #cf1322;
      font-weight: bold;
      border-radius: 4px;
      padding: 4px 8px;
      display: inline-block;
  }
  
  td:nth-child(2) { font-weight: 600; } 

  @media (max-width: 700px) {
      table, thead, tbody, th, td, tr {
          display: block;
      }

      thead {
          display: none;
      }

      .card {
          padding: 0;
          box-shadow: none;
      }

      tr {
          margin-bottom: 15px;
          background: white;
          box-shadow: 0 2px 6px rgba(0,0,0,0.05);
          border-radius: 10px;
          padding: 8px;
      }

      td {
          display: flex;
          justify-content: space-between;
          padding: 10px;
          border-bottom: 1px solid #eee;
      }

      td:last-child {
          border-bottom: none;
      }

      td::before {
          content: attr(data-label);
          font-weight: bold;
          color: #1f3a68;
          min-width: 100px;
      }
  }
</style>

</head>
<body>
<div class='container'>
<div class='card'>
<h1>Inventaire de la bibliothèque</h1>

<table>
<thead>
<tr>
<th>ID</th><th>Titre</th><th>Auteur</th><th>Année</th><th>Genre</th><th>Statut</th>
</tr>
</thead>
<tbody>
" > "$html_file"

  awk -F'|' '
  {
    statut_class = ($6 == "disponible" ? "statut-disponible" : "statut-emprunte")

    printf "<tr>"
    printf "<td data-label=\"ID\">%s</td>", $1
    printf "<td data-label=\"Titre\">%s</td>", $2
    printf "<td data-label=\"Auteur\">%s</td>", $3
    printf "<td data-label=\"Année\">%s</td>", $4
    printf "<td data-label=\"Genre\">%s</td>", $5
    printf "<td data-label=\"Statut\"><span class=\"%s\">%s</span></td>", statut_class, $6
    printf "</tr>\n"
  }' "$livres_file" >> "$html_file"

  echo "</tbody>
</table>
</div>
</div>
</body>
</html>" >> "$html_file"

  echo "HTML généré : $html_file"
}


emprunter_livre() {
    livres_file=$(file_livres)
    emprunts_file=$(file_emprunts)

    while :; do
      printf "ID du livre à emprunter (q pour quitter): "
      read -r id
      case "$id" in [qQ]) echo "Abandon de l'emprunt." ; return ;; esac
      grep -q -E "^${id}\|" "$livres_file" || { echo "ID incorrect, réessayez." ; continue; }
      statut=$(awk -F'|' -v id="$id" '$1==id{print $6}' "$livres_file")
      [ "$statut" = "emprunté" ] && { echo "Livre déjà emprunté." ; return ; }
      break
    done

    printf "Nom de l'emprunteur: "
    read -r emprunteur

    while :; do
      printf "Date d'emprunt (YYYY-MM-DD): " #on a fait le choix d'écrire manuelement les dates d'emprunts et de retour pour être 100% posix
      read -r date_emp
      case "$date_emp" in
        ????-??-??) 
          month_day=${date_emp#*-}
          month=${month_day%%-*}
          day=${month_day#*-}

          [ "$(expr "$month" + 0)" -ge 1 ] 2>/dev/null && [ "$(expr "$month" + 0)" -le 12 ] 2>/dev/null &&
          [ "$(expr "$day" + 0)" -ge 1 ] 2>/dev/null && [ "$(expr "$day" + 0)" -le 31 ] 2>/dev/null && break
          ;;
      esac
      echo "Format invalide. Exemple: 2025-11-16"
    done

    while :; do
      printf "Date de retour prévue (YYYY-MM-DD): "
      read -r date_ret
      case "$date_ret" in
        ????-??-??) 
          month_day=${date_ret#*-}
          month=${month_day%%-*}
          day=${month_day#*-}
          [ "$(expr "$month" + 0)" -ge 1 ] 2>/dev/null && [ "$(expr "$month" + 0)" -le 12 ] 2>/dev/null &&
          [ "$(expr "$day" + 0)" -ge 1 ] 2>/dev/null && [ "$(expr "$day" + 0)" -le 31 ] 2>/dev/null && break
          ;;
      esac
      echo "Format invalide. Exemple: 2025-11-30"
    done

    printf "%s|%s|%s|%s\n" "$id" "$emprunteur" "$date_emp" "$date_ret" >> "$emprunts_file"

    awk -F'|' -v id="$id" 'BEGIN{OFS="|"} $1==id{$6="emprunté"} {print}' "$livres_file" > "$livres_file.tmp"
    mv "$livres_file.tmp" "$livres_file"

    printf "%s|%s|%s|%s|EMPRUNT\n" "$id" "$emprunteur" "$date_emp" "$date_ret" >> "$(file_historique)"

    backup_auto
    echo "Emprunt enregistré: retour prévue le $date_ret"
}

retourner_livre() {
  printf '\n------------------------------------------------------------\n\n'
  livres_file=$(file_livres)
  emprunts_file=$(file_emprunts)

  while :; do
    printf "ID du livre à retourner (q pour quitter): "
    read -r id
    case "$id" in [qQ]) echo "Abandon du retour." ; return ;; esac
    grep -E "^${id}\|" "$livres_file" >/dev/null 2>&1 || { echo "Livre introuvable."; continue; }
    statut=$(awk -F'|' -v id="$id" '$1==id{print $6}' "$livres_file")
    [ "$statut" != "emprunté" ] && { echo "Ce livre n'est pas emprunté."; continue; }
    break
  done

  line=$(grep -E "^${id}\|" "$livres_file")
  title=$(echo "$line" | awk -F'|' '{print $2}')
  auteur=$(echo "$line" | awk -F'|' '{print $3}')
  annee=$(echo "$line" | awk -F'|' '{print $4}')
  genre=$(echo "$line" | awk -F'|' '{print $5}') 
  date_retour=$(date +%Y-%m-%d) #pas reelement posix mais universel


  awk -F'|' -v id="$id" 'BEGIN{OFS="|"} {if($1==id)$6="disponible"; print}' "$livres_file" > "$livres_file.tmp"
  mv "$livres_file.tmp" "$livres_file"

  grep -v -E "^${id}\|" "$emprunts_file" > "$emprunts_file.tmp" && mv "$emprunts_file.tmp" "$emprunts_file"

  printf "%s|%s|%s|%s|%s|RETOUR\n" "$id" "$title" "$auteur" "$annee" "$date_retour" >> "$(file_historique)"

  backup_auto
  echo "Retour enregistré pour le livre '$title', le '$date_retour'."
  printf '\n------------------------------------------------------------\n\n'
}



liste_emprunts() {
  livres_file=$(file_livres)
  emprunts_file=$(file_emprunts)
  [ ! -s "$emprunts_file" ] && echo "Aucun livre emprunté." && return

  while IFS='|' read -r id emprunteur date_emp date_ret; do
    title=$(awk -F'|' -v id="$id" '$1==id{print $2}' "$livres_file")
    printf "%s | %s | emprunteur: %s | emprunt: %s | retour prévu: %s\n" "$id" "$title" "$emprunteur" "$date_emp" "$date_ret"
  done < "$emprunts_file"
}

en_retard() {
  printf '\n------------------------------------------------------------\n\n'
  livres_file=$(file_livres)
  emprunts_file=$(file_emprunts)
  today=$(date +%Y-%m-%d) #pas reelement posix mais universel
  awk -F'|' -v today="$today" '$4 < today {print $0}' "$emprunts_file" | while IFS='|' read -r id emprunteur date_emp date_ret; do
    title=$(awk -F'|' -v id="$id" '$1==id{print $2}' "$livres_file")
    echo "         RETARD: Livre '$title' (ID $id) emprunté par $emprunteur, retour prévu le $date_ret   "
  done
  printf '\n------------------------------------------------------------\n\n'
}

historique_emprunts() {
  printf '\n------------------------------------------------------------\n\n'
  history=$(file_historique)
  [ ! -s "$history" ] && echo "Aucun historique." && return
  cat "$history"
  printf '\n------------------------------------------------------------\n\n'
}

menu_recherche() {
  printf '\n------------------------------------------------------------\n\n'
  while :; do
    
    echo "=== Recherche et filtres ==="
    echo "1) Recherche partielle par titre"
    echo "2) Recherche par auteur"
    echo "3) Filtrer par genre"
    echo "4) Filtrer par année (plage)"
    echo "5) Recherche avancée"
    echo "q) Retour"
    printf "Choix: "
    read -r c
    case "$c" in
      1) printf "Terme titre: "; read -r t; chercher_titre "$t"; pause_continue ;;
      2) printf "Auteur: "; read -r a; chercher_auteur "$a"; pause_continue ;;
      3) afficher_genre; printf "Genre: "; read -r g; chercher_genre "$g"; pause_continue ;;
      4) printf "Année début: "; read -r y1; printf "Année fin: "; read -r y2; chercher_annee "$y1" "$y2"; pause_continue ;;
      5) recherche_avancee; pause_continue ;;
      [qQ]) break ;;
      *) echo "Choix invalide."; pause_continue ;;
    esac
  done
}

menu_stats() {
  printf '\n------------------------------------------------------------\n\n'
  while :; do
    
    echo "=== Statistiques ==="
    echo "1) Nombre total de livres"
    echo "2) Répartition par genre "
    echo "3) Top 5 auteurs"
    echo "4) Livres par décennie"
    echo "q) Retour"
    printf "Choix: "
    read -r c
    case "$c" in
      1) stats_total; pause_continue ;;
      2) stats_genre_ascii; pause_continue ;;
      3) top_auteurs; pause_continue ;;
      4) livre_par_decenie; pause_continue ;;
      [qQ]) break ;;
      *) echo "Choix invalide." ; pause_continue ;;
    esac
  done
}

emprunt_menu() {
  printf '\n------------------------------------------------------------\n\n'
  while :; do
    
    echo "=== Gestion des Emprunts ==="
    echo "1) Emprunter un livre"
    echo "2) Retourner un livre"
    echo "3) Lister les livres empruntés"
    echo "4) Lister les retards"
    echo "5) Historique des emprunts"
    echo "q) Retour au menu principal"
    printf "Choix: "
    read -r choix
    case "$choix" in
      1) emprunter_livre; pause_continue ;;
      2) retourner_livre; pause_continue ;;
      3) liste_emprunts; pause_continue ;;
      4) en_retard; pause_continue ;;
      5) historique_emprunts; pause_continue ;;
      [qQ]) break ;;
      *) echo "Choix invalide."; pause_continue ;;
    esac
  done
}

backup_quotidien() {
    back_file=$(file_backups_dir)
    ts=$(date +%Y%m%d)
    mkdir -p "$back_file"

    cp "$(file_livres)" "$back_file/livres_$ts.txt" 2>/dev/null || true
    cp "$(file_emprunts)" "$back_file/emprunts_$ts.txt" 2>/dev/null || true

    echo "Backup quotidien créé dans $back_file le $ts ."
}


