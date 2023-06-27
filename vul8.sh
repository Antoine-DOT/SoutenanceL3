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
    echo -e "Vulnérabilités importantes dans les paquets installés :\n\e[33m$vuln_packages\e[0m"  # Résultats vulnérables en jaune
    echo "Vulnérabilités,Paquets installés,,$vuln_packages" >> "$results_csv"
else
    echo "Aucune vulnérabilité trouvée dans les paquets installés."
fi

# Vérification de l'état des ports et des services associés
echo "Vérification de l'état des ports et des services associés..."
echo "Port,Service,État" >> "$results_csv"

while read -r port; do
    service=$(lsof -i :$port | grep LISTEN | awk '{print $1}')
    nc -zv $ip_address "$port" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Ports,$port,$service,\e[91mOuvert\e[0m" >> "$results_csv"  # Port ouvert en rouge
    else
        echo "Ports,$port,$service,Fermé" >> "$results_csv"
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

# Vérification des mots de passe non sécurisés
echo "Vérification des mots de passe non sécurisés..."
insecure_passwords=$(awk -F':' '($2==""){print $1}' /etc/shadow)

if [[ -n $insecure_passwords ]]; then
    echo -e "\e[91mMots de passe non sécurisés trouvés :\n$insecure_passwords\e[0m"  # Résultats non sécurisés en rouge
    echo "Mots de passe non sécurisés,Utilisateur,," >> "$results_csv"
    while IFS= read -r line; do
        echo "Mots de passe non sécurisés,$line,," >> "$results_csv"
    done <<< "$insecure_passwords"
else
    echo "Aucun mot de passe non sécurisé trouvé."
fi

echo "Terminé. Les résultats ont été exportés dans $results_csv."
