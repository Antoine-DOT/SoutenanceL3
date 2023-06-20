SoutenanceL3

Projet : Durcissement de l'OS

Ce projet vise à renforcer la sécurité de notre système d'exploitation (OS). Pour faciliter la collaboration, voici un guide simple pour utiliser GitHub.

Guide d'utilisation de GitHub

Étape 1 : Cloner le référentiel
Pour commencer, vous devez cloner le référentiel sur votre ordinateur. Ouvrez votre terminal et exécutez la commande suivante :


git clone https://github.com/Antoine-DOT/SoutenanceL3
Cela téléchargera le référentiel sur votre machine locale.

Maintenant, lancez VSC, connectez vous avec github et ouvrez le dossier que vous venez de cloner

Étape 2 : Travailler sur le code
Assurez-vous qu'une seule personne travaille sur le code à la fois pour éviter les conflits. Avant de commencer à travailler sur le code ou un autre document, vérifiez que vous avez la dernière version en exécutant la commande suivante :

git pull

Cela vous mettra à jour avec les dernières modifications effectuées par d'autres collaborateurs.

Étape 3 : Ajouter les modifications
Une fois que vous avez terminé vos modifications et que vous êtes satisfait de votre travail, il est temps de les ajouter au suivi de version. Dans votre terminal, assurez-vous d'être positionné dans le dossier du référentiel, puis exécutez la commande suivante :


git add .
Cela ajoutera toutes les modifications que vous avez effectuées.

Étape 4 : Effectuer un commit
Un commit est une validation de vos modifications. Avant de l'effectuer, assurez-vous d'avoir un message clair décrivant les changements que vous avez apportés. Dans votre terminal, exécutez la commande suivante :


git commit -m 'Ajout de fonctionnalité'

Remplacez 'Ajout de fonctionnalité' par un message approprié à vos modifications.

Étape 5 : Envoyer les modifications
Maintenant que vous avez effectué un commit, vous devez envoyer vos modifications vers le référentiel distant sur GitHub. Dans votre terminal, exécutez la commande suivante :

git push

Cela enverra vos modifications vers le référentiel GitHub, les rendant accessibles à tous les collaborateurs.

En résumé

faites dans cette ordre là 

git pull (pour être à jour et commencer à travailler)
git add . (pour ajouter vos modification)
git commit -m 'message' (pour enregistrer votre code)
git push (pour le rendre accessible à tout le monde)

Voilà ! Vous êtes maintenant prêt à collaborer avec succès en utilisant GitHub pour notre projet de durcissement de l'OS.
