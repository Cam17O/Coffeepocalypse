# Coffeepocalypse

## Technique

- Godot — code fait avec assistance IA
- 2D — sprites faits main (16*16 pixel)
- ui professionel belle et propre
- Enregistrement local avec possibilité d'import / export


- si possible, cohérent et optimisé  :
  - classe, instance de classe, héritage, ect pour chaque élément
  - sorte d'api pour gérer chaque event (bateau spawn, decharge, chat commence à travailler, boit, fini de boire, se balade)
  - code compartimentiser pour un machimum de faciliter de compréhension (ex : mouvement, action, amélioration, placement, gestion café chacun dans un fichier différent pour la machine à café)


## Type de jeu

- Incrémentale
- Simulation
- Un peu d'idle

## Fonctionnalités

### Île déserte (pas de lore pour l'instant)

- Bateau vient de hors de l'île pour amener les ressources premières

### Machine à café

x = 5 (à équilibrer)

- 1 machine à café de type 1 au début de la partie
- Possibilité de poser plusieurs machines du même type (chacune à son propre niveau) (prix augmente à chaque élément du même type posé)
- Débloquer un nouveau type de machine via l'arbre de compétence : plus chère mais meilleures stats dès le level 1 (sprites différents)
- Chaque machine a un état de propreté : descend régulièrement (impacte la satisfaction gagnée par café vendu ; si en dessous d'un seuil, ajoute une valeur négative)
- Chaque machine a un état de durabilité (genre neuf, abîmée, cassée) : descend à chaque café à partir d'un seuil, possibilité d'avoir des problèmes à chaque café :
  - Prend l'argent mais ne donne pas de café ⇒ client obligé de payer 2, 3 fois max (impacte la satisfaction beaucoup si plusieurs fois pas de café à la suite) — UI à afficher quand très bas
  - Eau sans ou avec peu de café (réduit la satisfaction) (si que eau, chance que le chat rachète un café ; si que eau une seconde fois, réduit satisfaction++) — UI à afficher quand très bas
- Améliorations de niveau (chaque amélioration d'un élément plus chère que la précédente, niveau indépendant pour chaque élément) :
  - Plus rapide à faire du café (augmente gain de satisfaction par café vendu)
  - Stock de matière première max augmenté (+5 tous les x niveaux et pas à chaque niveau) — UI à afficher quand très bas
  - Meilleur ratio (nombre de matière première ⇒ nombre de cafés faits avec) (ne se passe que tous les x niveaux et pas à chaque niveau)
  - Prix du café augmenté
  - Meilleur goût (ne se passe que tous les x niveaux et pas à chaque niveau) (augmente gain de satisfaction par café vendu)
  - Meilleure durabilité max (ne se passe que tous les x niveaux et pas à chaque niveau)
  - Meilleur taux de descente de durabilité
  - Meilleure propreté max (ne se passe que tous les x niveaux et pas à chaque niveau)
  - Meilleur taux de descente de propreté
- Actions :
  - Clic droit sur élément : ouvrir le menu à l'onglet correspondant
  - Clic gauche : prendre un café (le joueur prend juste un café (doit bloquer mouvement (immobiliser)), pas de bonus ou quoi que ce soit)
  - E : ouvre petite popup : X1 dépose un café brut dans la machine, X10 dépose 10 cafés bruts dans la machine, MAX dépose tout le café présent dans l'inventaire ou max du storage de la machine

### Zone d'arrivage des matières premières

- 1 storage de type 1 au début de la partie
- Possibilité de remplacer le storage par un de type supérieur, exemple : pile of box, building, giga storage, dimension portal storage, black hole. Ça augmente beaucoup le storage (sprites différents)
- Amélioration (reset niveau à 1 quand nouveau type de storage) :
  - Plus de stockage max — UI à afficher quand très bas
  - Vitesse de déchargement des bateaux augmentée
- Évolution :
  - Remplacer (sprites différents) (reset niveau à 1 quand nouveau type de storage) (besoin de l'avoir débloqué dans l'arbre de compétence)
- Actions :
  - Clic droit sur élément : ouvrir le menu à l'onglet correspondant
  - Clic gauche : prendre du café : remplit l'inventaire du joueur au max

### Boats

- Arrive de loin dans l'océan (environ 1 min de trajet au niveau 1), quand il part pour venir à l'île il doit dépenser l'argent équivalent au prix des matières premières qu'il transporte
- Stockage max
- Vitesse
- Une fois arrivé au storage, dépose tout dedans :
  - Si storage plein : attendre que le storage se vide, le remplir ainsi de suite jusqu'à ce que le bateau soit vide
- Amélioration :
  - Plus de stockage max
  - Vitesse de déplacement
- Évolution :
  - Remplacer (sprites différents) (reset niveau à 1 quand nouveau type de boat) (besoin de l'avoir débloqué dans l'arbre de compétence)
- Actions :
  - Clic droit sur élément : ouvrir le menu à l'onglet correspondant

### Clients chats

- Chat spawn dans maison de chat
- Barre de vie
- Level (chaque chat a un level individuel) — UI pour afficher brièvement level up
- Boost lieu de travail
- A une barre d'énergie : — UI pour afficher énergie
  - Pleine : va travailler
  - Vide : va chercher du café
- Améliorations (gagnent de l'exp en travaillant) :
  - Vitesse plus rapide
  - Meilleur boost de travail (ne se passe que tous les x niveaux et pas à chaque niveau)
  - Plus de PV

### Talent tree

Arbre des talents qui permet de débloquer de nouvelles fonctionnalités au prix de satisfaction

- ui - un cercle pour chaque catégorie (image) :
  - cercle plus petit relié au grand cercle (catégorie) ou au petit cercle de préréquis par un trait (images) : 
    - click => aprendre la compétence
    - hover => afficher détail de la compétence survolé

- Débloquer robot :
  - Storage : transporte des matières premières du storage à la machine la plus vide automatiquement
  - Cleaner : clean les machines (remet à propre)
  - Réparateur : répare les machines (remet à neuf)
- Débloquer nouveau type de :
  - Machines
  - Cat's house
  - Storage
- Améliorer le joueur :
  - Quantité transportable
- Storage :
  - Auto restock

### Robot

- Storage : transporte des matières premières du storage à la machine la plus vide automatiquement
- Cleaner : clean la machine (remet à propre) la plus sale
- Réparateur : répare la machine (remet à neuf) la plus abîmée

### Joueur

- Mouvement : Z, Q, S, D
- Consommer le produit d'une machine (plus tard, pas faire mtn) (boost certaines stats du joueur)
- Téléphone (menu Tab)(grande dialog qui prend 99% de l'écran) :
  - Menu (player, cats, machines, cat's house, storage, boats, talent tree, robot) (menu vertical à gauche, tout le reste s'affiche à droite du menu)
  - **Player :**
    - Image du player + afficher plein d'infos sur le player
  - **Cats :**
    - Tableau triable avec les infos les plus importantes (une ligne un chat)
    - Clic sur ligne du tableau ⇒ popup : image + toutes les infos du chat + à gauche et à droite flèche pour passer au chat d'avant ou d'après
  - **Machines :**
    - Bouton ajouter machine : ouvre popup avec liste des machines (image bloquée pour celles pas encore débloquées) image, nom et description de chaque machine : au clic sur élément de la liste construire (si autorisé) une nouvelle machine
    - Tableau triable avec les infos les plus importantes (une ligne une machine) + au-dessus le bouton ajouter machine
    - Clic sur ligne du tableau ⇒ popup : image + toutes les infos de la machine + à gauche et à droite flèche pour passer à la machine d'avant ou d'après, bouton améliorer machine
  - **Cat's house :**
    - Bouton ajouter cat house : ouvre popup avec liste des cat house (image bloquée pour celles pas encore débloquées) image, nom et description de chaque cat house : au clic sur élément de la liste construire (si autorisé) une nouvelle cat house
    - Tableau triable avec les infos les plus importantes (une ligne une cat house)
    - Clic sur ligne du tableau ⇒ popup : image + toutes les infos de la cat house + à gauche et à droite flèche pour passer à la cat house d'avant ou d'après, bouton améliorer cat house
  - **Storage :**
    - Image du storage + afficher plein d'infos sur le storage
    - Bouton auto restock :
      - Si oui : demande choix des bateaux utilisés et les commandes en boucle jusqu'à fin auto restock
      - Si non : demande choix du bateau, demande quantité de stock et bouton commander
    - Liste des commandes en cours
    - Bouton améliorer
    - Bouton évoluer : fait passer à la sprite du storage supérieur
  - **Boats :**
    - Bouton ajouter boat : ouvre popup avec liste des boats (image bloquée pour celles pas encore débloquées) image, nom et description de chaque boat : au clic sur élément de la liste ajouter (si autorisé) un nouveau boat
    - Tableau triable avec les infos les plus importantes (une ligne un boat)
    - Clic sur ligne du tableau ⇒ popup : image + toutes les infos du boat + à gauche et à droite flèche pour passer au boat d'avant ou d'après, bouton améliorer boat, bouton évoluer boat
  - **Talent tree :**
    - Arbre des talents :
      - Clic sur un talent ⇒ popup : image, nom, description, bouton apprendre
  - **Robot :**
    - Bouton ajouter robot : ouvre popup avec liste des robots (image bloquée pour celles pas encore débloquées) image, nom et description de chaque robot : au clic sur élément de la liste ajouter (si autorisé) un nouveau robot
    - Tableau triable avec les infos les plus importantes (une ligne un robot)
    - Clic sur ligne du tableau ⇒ popup : image + toutes les infos du robot + à gauche et à droite flèche pour passer au robot d'avant ou d'après, bouton améliorer robot

### Idées

- Ferme : production des ressources premières / voir exclusives directement sur l'île
- Pêche :
  - Trouver des équipements équipables aux chats ou aux machines…
- systeme de prestige