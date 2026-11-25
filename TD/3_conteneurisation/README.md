# TD 3 - Conteneurisation

![docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![rabbitmq](https://img.shields.io/badge/rabbitmq-%23FF6600.svg?style=for-the-badge&logo=rabbitmq&logoColor=white)

| Dossier | Contenu |
| --- | --- |
| [`frontend/`](./frontend) | Page HTML/CSS servie par `nginx` |
| [`backend/`](./backend) | Conteneur de debug `toolbox` (Debian) |
| [`TP-Rabbitmq/`](./TP-Rabbitmq) | Bonus : producteur / consommateur RabbitMQ |

---

## 1. Une impression de déjà vu - `frontend`

```dockerfile
FROM nginx:latest
COPY index.html /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
EXPOSE 80
```

**Quel est le point d'entrée de l'application ? Quelle commande va s'exécuter au démarrage du conteneur ?**

Le `Dockerfile` ne définit ni `ENTRYPOINT` ni `CMD` : ils sont **hérités de l'image `nginx`**.

* `ENTRYPOINT ["/docker-entrypoint.sh"]` : un script qui prépare la configuration.
* `CMD ["nginx", "-g", "daemon off;"]` : il lance nginx **au premier plan**. Le processus principal du conteneur reste vivant, sinon le conteneur s'arrêterait aussitôt.

On peut le vérifier avec `docker inspect nginx:latest --format '{{.Config.Entrypoint}} {{.Config.Cmd}}'`.

**Construction et exécution :**

```shell
cd frontend
docker build . -t mon-frontend
docker run -d --name frontend -p 8080:80 mon-frontend
```

`-p 8080:80` redirige le port `8080` de la machine vers le port `80` exposé par le conteneur. Le site est ensuite visible sur [http://localhost:8080](http://localhost:8080).

**On modifie `index.html` et on redéploie. Que peut-on observer ?**

Tant qu'on ne reconstruit pas l'image, **la page ne change pas**. Les fichiers sont copiés dans l'image au moment du `docker build` : le conteneur ne lit pas les fichiers de notre machine. Pour voir la modification, il faut :

```shell
docker stop frontend && docker rm frontend
docker build . -t mon-frontend
docker run -d --name frontend -p 8080:80 mon-frontend
```

Au rebuild, Docker réutilise le cache pour la couche `FROM nginx` : seules les couches `COPY` qui ont changé sont reconstruites. Une image est **immuable** : chaque modification donne une nouvelle image.

---

## 2. Explorer ce micro-environnement - `backend`

```dockerfile
FROM debian:latest
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash htop vim net-tools \
    && rm -rf /var/lib/apt/lists/*
ENV OWNER=Ali
RUN useradd nonroot
USER nonroot
CMD ["sleep", "3600"]
```

> `netstat` est fourni par le paquet `net-tools`.

**Pourquoi n'avons-nous pas utilisé `EXPOSE` ?**

Ce conteneur ne fait tourner **aucun service réseau** : il exécute seulement `sleep 3600`. Il n'y a donc aucun port à documenter ni à publier. Il sert de boîte à outils dans laquelle on entre avec `docker exec`. Par ailleurs, `EXPOSE` ne fait que documenter un port : c'est `-p` qui le publie vraiment.

**Construction et utilisation :**

```shell
cd backend
docker build . -t toolbox
docker run -d --name toolbox-ctn toolbox        # terminal 1
docker exec -it toolbox-ctn /bin/bash           # terminal 2
echo $OWNER     # -> Ali
htop            # processus : seulement bash et sleep
netstat -tulpn  # aucun port en écoute
```

**On lance le frontend, puis `curl http://<IP-host>:8080` depuis la toolbox. Que constate-t-on ?**

La requête **fonctionne** : on récupère le HTML du frontend. Les deux conteneurs sont isolés l'un de l'autre, mais la toolbox peut joindre le frontend **en passant par la machine hôte**. On utilise l'IP de l'interface Docker (passerelle du réseau `bridge`, souvent `172.17.0.1`, ou `host.docker.internal` sous Docker Desktop) et le port publié `8080`.

En revanche, `curl http://localhost:8080` **échoue** depuis la toolbox : `localhost` désigne le conteneur lui-même, pas la machine hôte.

---

## 3. Gestion des droits utilisateur

| | Sans `USER` | Avec `USER nonroot` |
| --- | --- | --- |
| `whoami` | `root` | `nonroot` |
| `apt install curl` | ✅ installé | ❌ `Permission denied` (`are you root?`) |

**Qu'en déduisez-vous ?**

Par défaut, un conteneur tourne en **root**. Un processus compromis aurait alors tous les droits dans le conteneur, et plus de risques de s'en échapper. Avec `USER nonroot`, on applique le **principe du moindre privilège** : l'application ne peut plus installer de paquets ni modifier le système. Il faut donc installer tout ce dont on a besoin (comme `curl`) **au moment du build**, avant l'instruction `USER`, et pas à l'exécution.

---

## 4. Sauvegardons ce joli frontend - Artifact Registry

```shell
gcloud auth activate-service-account student@polytech-dijon.iam.gserviceaccount.com --key-file="./student.json"
gcloud config set project polytech-dijon
gcloud auth configure-docker europe-west1-docker.pkg.dev

docker tag mon-frontend europe-west1-docker.pkg.dev/polytech-dijon/polytech-dijon/frontend-2026:moussaoui
docker push europe-west1-docker.pkg.dev/polytech-dijon/polytech-dijon/frontend-2026:moussaoui
```

Structure du tag : `<region>-docker.pkg.dev` / `<projet-gcp>` / `<registre>` / `<image>:<tag>`.

> [!warning]
> `student.json` n'est jamais versionné (`**/student.json` dans le `.gitignore`).

---

## Bonus - RabbitMQ Hello World

```shell
docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3.12-management
```

```shell
cd TP-Rabbitmq
pip install -r requirements.txt
python receive.py   # terminal 1 : consommateur, attend les messages
python send.py      # terminal 2 : producteur -> " [x] Sent 'Hello World!'"
```

Le consommateur affiche ` [x] Received Hello World!`. L'interface de gestion est disponible sur [http://localhost:15672](http://localhost:15672) (identifiants `guest` / `guest`).
