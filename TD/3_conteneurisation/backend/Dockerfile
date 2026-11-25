# Conteneur de debug ("toolbox")
FROM debian:latest

# bash, htop, vim et netstat (fourni par le paquet net-tools)
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash htop vim net-tools \
    && rm -rf /var/lib/apt/lists/*

# Variable d'environnement avec le prénom
ENV OWNER=Ali

# Utilisateur non root pour l'exécution
RUN useradd nonroot
USER nonroot

# Debian n'a pas de commande par défaut : on garde le conteneur actif 1 h
CMD ["sleep", "3600"]
