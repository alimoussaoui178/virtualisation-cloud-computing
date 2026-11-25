# Image de base : dernière version de nginx
FROM nginx:latest

# Copie des fichiers du site dans le dossier servi par nginx
COPY index.html /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/

# Port servi par nginx
EXPOSE 80

# Pas de CMD : on hérite de celui de l'image nginx
#   ENTRYPOINT ["/docker-entrypoint.sh"]
#   CMD ["nginx", "-g", "daemon off;"]
