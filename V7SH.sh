#!/bin/bash
ip_address=$(ifconfig ens33 | grep -oP 'inet\s+\K[\d.]+')
# Vérification des privilèges de superutilisateur
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que superutilisateur."
   exit 1
fi
# Mettre à jour la liste des paquets
apt update

# Définir le fichier CSV de sortie
results_csv="results.csv"

# Vérifier les vulnérabilités connues dans les paquets installés
echo "Vérification des vulnérabilités dans les paquets installés..."
vuln_packages=$(apt list --upgradable 2>/dev/null | grep security)

if [[ -n $vuln_packages ]]; then
    echo -e "Vulnérabilités importantes dans les paquets installés :\n\e[91m$vuln_packages\e[0m"  # Résultats vulnérables en rouge
    echo "Vulnérabilités,Paquets installés,,$vuln_packages" >> "$results_csv"
else
    echo "Aucune vulnérabilité trouvée dans les paquets installés."
fi

# Vérification de l'état des ports
echo "Vérification de l'état des ports..."
echo "Port,Élément,État" >> "$results_csv"

while read -r port; do
    nc -zv $ip_address "$port" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Ports,Port,$port,\e[91mOuvert\e[0m" >> "$results_csv"  # Port ouvert en rouge
    else
        echo "Ports,Port,$port,Fermé" >> "$results_csv"
    fi
done < <(netstat -tuln | awk 'NR>2 {print $4}' | awk -F ':' '{print $NF}' | sort -u)

# Vérifier les versions des services exposés
echo "Vérification des versions des services exposés..."
dpkg -l | awk '/^ii/ {print "Mises à jour,Paquet installé," $2 "," $3}' >> "$results_csv"

# Vérification des vulnérabilités du kernel
echo "Vérification des vulnérabilités du kernel..."
kernel_version=$(uname -r)
latest_release=$(apt-cache policy linux-image-generic | awk -F '[ -]' '/Candidate/ {print $4}')
if [[ "$latest_release" != "$kernel_version" ]]; then
    echo "Mises à jour,Kernel,$kernel_version,\e[91m$latest_release\e[0m" >> "$results_csv"  # Mise à jour en rouge
else
    echo "Mises à jour,Kernel,$kernel_version,$latest_release" >> "$results_csv"
fi
# Vérification des fichiers avec des permissions trop permissives
echo "Vérification des fichiers avec des permissions trop permissives..."
vulnerable_files=$(find / -type f -perm /o+w 2>/dev/null)

if [[ -n $vulnerable_files ]]; then
    echo -e "\e[91m$vulnerable_files\e[0m"  # Résultats vulnérables en rouge
    echo "Permissions,Fichier,Permissions,Propriétaire" >> "$results_csv"
    while IFS= read -r line; do
        permissions=$(ls -l "$line" | awk '{print $1}')
        owner=$(ls -l "$line" | awk '{print $3}')
        echo "Permissions,$line,$permissions,$owner" >> "$results_csv"
    done <<< "$vulnerable_files"
else
    echo "Aucun fichier trouvé avec des permissions trop permissives."
fi

echo "Terminé. Les résultats ont été exportés dans $results_csv."