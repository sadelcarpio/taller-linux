# Mi primera aplicación en Cloud Run

## Requisitos
`docker`: https://docs.docker.com/engine/install/ubuntu/ (Ubuntu), https://docs.docker.com/desktop/setup/install/windows-install/ (Windows)

`gcloud`: https://cloud.google.com/sdk/docs/install

`uv`: https://docs.astral.sh/uv/getting-started/installation/

`git`: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

(Opcional) Visual Studio Code: https://code.visualstudio.com/download

(Opcional) Pycharm: https://www.jetbrains.com/help/pycharm/installation-guide.html

`make`: sudo apt-get install make

## Pasos a seguir
Utilizar una distribución de Linux (puede ser cloud shell, wsl o nativo)
```shell
$ touch .env
# Agregar GOOGLE_API_KEY a .env
GOOGLE_API_KEY=<api-key>
$ export PROJECT_ID=<tu-project-id>
# Login con gcloud
$ make configure-gcloud
# Habilitar APIs
$ make enable-gcloud-apis
# Desplegar toda la aplicación (Artifact Registry, Secrets, Cloud Run)
$ make deploy-all
# Redeploy de aplicacion (despues de deploy-all)
$ make deploy
# Limpiar todos los recursos
$ make delete-all
```
