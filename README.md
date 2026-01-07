Gestionnaire de Bibliothèque Personnelle

Programmation d'un système de gestion de bibliothèque personnel en Shell Posix.


Objectifs du projet

* Manipuler des fichiers texte (CSV-like/fichiers plats).
* Concevoir un mini-système de gestion sans base de données.
* Créer un menu interactif et une interface utilisateur en Shell.
* Assurer la portabilité intégrale du code en respectant la norme POSIX Shell
* Implémenter des fonctions de recherche avancée, filtrage et statistiques.
* Mettre en place un système de sauvegarde et de backup automatique.


Fonctionnalités principales


Gestion des livres

* Ajouter un livre (ID généré automatiquement).
* Modifier un livre existant.
* Supprimer un livre.
* Lister les livres avec pagination.


Recherche et filtres

* Recherche partielle par titre.
* Recherche par auteur.
* Filtrage par genre.
* Filtrage par année (plage).
* Recherche avancée (combinaison de critères).


Statistiques et rapports

* Nombre total de livres.
* Répartition par genre (graphique ASCII).
* Top 5 auteurs les plus présents.
* Livres par décennie.
* Export des résultats en HTML.


Gestion des emprunts

* Emprunter un livre (avec dates et emprunteur).
* Retourner un livre.
* Lister les livres empruntés.
* Détecter les retards.
* Historique des emprunts.


Sauvegardes

* Système de sauvegarde automatique à chaque modification
* Sauvegarde manuelle
* Sauvegarde quotidienne automatique



Organisation des fichiers

* 'bibliotheque.sh' → Script principal (menu interactif).
* 'lib_functions.sh' → Bibliothèque de fonctions.
* 'data/livres.txt' → Base des livres (format: 'ID|Titre|Auteur|Année|Genre|Statut').
* 'data/emprunts.txt' → Base des emprunts (format: 'ID|Livre|Emprunteur|Date_Emprunt|Date_Retour_Prévue').
* 'data/historique.txt' → Historique des emprunts et retours.
* 'data/backups/' → Sauvegardes (automatiques, quotidiennes et manuelles).


Utilisation

1. Donner les droits d'exécution :
   chmod +x bibliotheque.sh
   chmod -R u+rwX /chemin/absolu/vers/projet_bibliotheque/
2. Lancer l'application
   ./bibliotheque.sh

Pour une sauvegarde quotidienne automatique à 00h (remplacer /chemin/absolu/vers/ par le véritable chemin absolu) :
crontab -e
0 0 \* \* \* /chemin/absolu/vers/bibliotheque.sh --backup-quotidien

