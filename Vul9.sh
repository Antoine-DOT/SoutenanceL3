#!/bin/bash
ip_address=$(ifconfig ens33 | grep -oP 'inet\s+\K[\d.]+')

# Vérification des privilèges de superutilisateur
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que superutilisateur."
   exit 1
fi

# Mettre à jour la liste des paquets
apt update

# Définir le fichier HTML de sortie avec l'heure de création
current_date=$(date +"%Y-%m-%d_%H-%M-%S")
results_html="/root/VisionGuardExploit/VisionGuard_${current_date}.html"

# Création du fichier HTML avec le rapport
cat > "$results_html" <<EOF
<html>
<head>
<style>
body {
    font-family: Arial, sans-serif;
    margin: 40px;
}

h1 {
    color: #333;
}

table {
    border-collapse: collapse;
    margin-top: 20px;
    width: 100%;
}

th, td {
    border: 1px solid #ddd;
    padding: 8px;
}

th {
    background-color: #f2f2f2;
}

.logo {
    display: block;
    text-align: center;
    margin-bottom: 20px;
}

.red {
    color: red;
}

</style>
</head>
<body>
<div class="logo">
    <img src="/tmp/10.png" alt="Logo" width="200">
</div>
<h1>Rapport VisionGuard - $(date +"%d/%m/%Y %H:%M")</h1>

<h2>Vulnérabilités dans les paquets installés</h2>
<table>
    <tr>
        <th>Vulnérabilités</th>
        <th>Paquets installés</th>
    </tr>
EOF

# Vérification des vulnérabilités connues dans les paquets installés
vuln_packages=$(apt list --upgradable 2>/dev/null | grep security)
if [[ -n $vuln_packages ]]; then
    IFS=$'\n'
    for package in $vuln_packages; do
        echo "<tr><td><span class=\"red\">$package</span></td><td>Package Description</td></tr>" >> "$results_html"
    done
else
    echo "<tr><td>Aucune vulnérabilité trouvée dans les paquets installés.</td><td></td></tr>" >> "$results_html"
fi

cat >> "$results_html" <<EOF
</table>

<h2>État des ports et services associés</h2>
<table>
    <tr>
        <th>Port</th>
        <th>Service</th>
        <th>État</th>
    </tr>
EOF

# Vérification de l'état des ports et des services associés
while read -r port; do
    service=$(lsof -i :$port | grep LISTEN | awk '{print $1}')
    nc -zv $ip_address "$port" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "<tr><td>$port</td><td>$service</td><td><span class=\"red\">Ouvert</span></td></tr>" >> "$results_html"
    else
        echo "<tr><td>$port</td><td>$service</td><td>Fermé</td></tr>" >> "$results_html"
    fi
done <<< "22
80
443"

cat >> "$results_html" <<EOF
</table>

<h2>Mise à jour du système</h2>
<table>
    <tr>
        <th>Type</th>
        <th>Version actuelle</th>
        <th>Dernière version disponible</th>
    </tr>
EOF

# Vérification des mises à jour du système
kernel_version=$(uname -r)
latest_kernel_version=$(apt list --upgradable linux-image* 2>/dev/null | grep -oP '(?<=linux-image-)[^=]+')
if [[ -n $latest_kernel_version ]]; then
    if [[ $kernel_version != $latest_kernel_version ]]; then
        echo "<tr><td>Kernel</td><td><span class=\"red\">$kernel_version</span></td><td><span class=\"red\">$latest_kernel_version (pouvant être mis à jour)</span></td></tr>" >> "$results_html"
    else
        echo "<tr><td>Kernel</td><td>$kernel_version</td><td>$latest_kernel_version</td></tr>" >> "$results_html"
    fi
else
    echo "<tr><td>Kernel</td><td>$kernel_version</td><td>Aucune mise à jour disponible</td></tr>" >> "$results_html"
fi

cat >> "$results_html" <<EOF
</table>

<h2>Mots de passe non sécurisés</h2>
<table>
    <tr>
        <th>Utilisateur</th>
        <th>Mot de passe</th>
    </tr>
EOF

# Vérification des mots de passe non sécurisés
insecure_passwords=$(cat /etc/shadow | awk -F: '($2 == "" || $2 == "*") {print $1}')
if [[ -n $insecure_passwords ]]; then
    IFS=$'\n'
    for user in $insecure_passwords; do
        password="<span class=\"red\">Non sécurisé</span>"
        echo "<tr><td>$user</td><td>$password</td></tr>" >> "$results_html"
    done
else
    echo "<tr><td>Aucun mot de passe non sécurisé trouvé.</td><td></td></tr>" >> "$results_html"
fi

cat >> "$results_html" <<EOF
</table></body></html>
EOF

echo "Le rapport VisionGuard a été généré avec succès."

# Déplacer le fichier HTML vers le répertoire de destination
mv "$results_html" "/root/VisionGuardExploit/"
