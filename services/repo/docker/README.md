# grdk-repo-docker

GRDKRepoDocker - Instalação do Docker para GRDKRepoRunner com .gitlab-ci.yml

## Pré-requisitos

* GRDKRepo

## Instalação

1. Executar

	``docker build -t repo-di.grdk:5000/grdk-repo-docker:latest .``

2. Executar

	``docker push repo-di.grdk:5000/grdk-repo-docker:latest``

3. Editar config.toml no docker-runner

	``privileged = true``
	``volumes = ["/var/run/docker.sock:/var/run/docker.sock","/cache"]``
	
4. Editar .gitlab-ci.yml do projeto

	``image: repo-di.grdk:5000/grdk-repo-docker``

## Acesso

http://repo-di.grdk:5000/v2/grdk-repo-docker/tags/list
