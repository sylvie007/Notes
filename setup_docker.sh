#Setup docker 

sudo apt update
sudo apt install docker.io -y
sudo apt install docker-compose -y 
sudo su -
echo '{ "insecure-registries":["172.31.27.186:5000"] }' >> /etc/docker/daemon.json
sudo systemctl stop docker.socket 
sudo systemctl start docker
sudo chmod 777 /var/run/docker.sock

kapacitor-1.5.9.tar.gz

docker --version

docker rmi $repository/$i:$tag_name@image_digest

For remove container:
docker rmi {container_id}

For run the container:
docker run -it {IMAGE ID}/bin/bash



../policy  ../compiler  ../gawp  ../workflow  ../so
 docker ps -a 
docker rmi  172.31.27.186:5000/tosca-gawp:26-Jan-2024@sha256:ea2c7948b3dec25005dac8bbc1774c639d1ada9ea5701a00b38b6215b083af6b
docker pull 172.31.27.186:5000/tosca-gawp:26-Jan-2024

docker push 172.31.27.186:5000/dcaf-kapacitor-filter:29-Dec-2023

docker push 172.31.27.186:5000/tosca-compiler:30-Jan-2024
docker pull 172.31.27.186:5000/tosca-compiler:30-Jan-2024

 docker build -f Dockerfile.compiler.multistage -t 172.31.27.186:5000/tosca-compiler:30-Jan-2024 --build-arg user=rajeshvkothari --build-arg password=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 --no-cache .
 
 
 
 docker build -f Dockerfile.kapacitor-filter.multistage -t 172.31.27.186:5000/dcaf-kapacitor-filter:06-Jan-2024 --build-arg user=rajeshvkothari --build-arg password=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 --no-cache .
 docker push 172.31.27.186:5000/dcaf-kapacitor-filter:06-Jan-2024
 docker push 172.31.27.186:5000/dcaf-kapacitor-filter:05-Jan-2024
 
 docker build -f Dockerfile.gwec-aws-credentials-without-kubectl-with-vault.multistage -t 172.31.27.186:5000/gwec-image:08-Jan-2024 --no-cache .
 docker push 172.31.27.186:5000/gwec-image:08-Jan-2024
 
 302 - 172.31.19.229
 303 - 172.31.21.227
 
======================================================================================

docker ps -a:  To see all the running containers in your machine.
docker stop 172.31.27.186:5000/tosca-gawp:26-Jan-2024:  To stop a running container.
docker rm <container_id>:  To remove/delete a docker container(only if it stopped).
docker image ls:  To see the list of all the available images with their tag, image id, creation time and size.
docker rmi <image_id>:  To delete a specific image.
delete rmi -f <image_id>:  To delete a docker image forcefully
docker rm -f (docker ps -a | awk '{print$1}'): To delete all the docker container available in your machine
docker image rm <image_name>: To delete a specific image
To remove the image, you have to remove/stop all the containers which are using it.

docker system prune -a: To clean the docker environment, removing all the containers and images.

======================================================================================

 
 
 
 docker build -f Dockerfile.kapacitor-filter.multistage -t $repository/dcaf-kapacitor-filter:$tag_name  .
 
 
 
COPY RestApi /opt/app/
RUN chmod +x /opt/app/RestApi


# Stop and remove containers using the image
docker ps -a | grep "1234.1234:123/rush-shin:26-Jan-2024" | awk '{print $1}' | xargs -I {} docker stop {}
docker ps -a | grep "1234.1234:123/rush-shin:26-Jan-2024" | awk '{print $1}' | xargs -I {} docker rm {}

# Delete the image
docker rmi 1234.1234:123/rush-shin:26-Jan-2024



can you add ...gwec-image:29-Dec-2023..... image tag in below metadata code
   metadata:
   gwec-image: "gwec-helm-with-aws-credentials"
   argowfsteps: "multi-wfc"
   model-name: "dcaf-cmts-multi-list"
   deployable: "true"
   
   
   
   
/opt/app/gin/multi19/artifacts/chart/create.sh: line 54: ./gin-val-fetch: cannot execute binary file: Exec format
error


go build -o gin-val-fetch ./


GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build


argo submit multi23_deploy_argo_workflow_template.json -n gin

kubectl exec -it multi23---2hkx7 sh -n gin -c gin-predeployment-step
kubectl exec -it multi25---hmpvm sh -n gin -c gin-predeployment-step
kubectl exec multi25---hmpvm -- sh -n gin -c gin-predeployment-step

echo '{\"gin\": \"172.31.19.229\", \"dmaapPort\": \"31502\" }' \u003e gin.json \u0026\u0026 cat gin.json

./gin-val-fetch -key=gin
./gin-val-fetch -key =gin


go build -o gin-val-fetch ./opt/app

 docker pull $repository/$i:$TAG_NAME
docker pull gwec-image:29-Dec-2023
docker pull gawp-image:01-Jan-2024



Use for commite changes through vs code.
for setup github on vs code for 1st time:

git config -l
git config --get-all user.name "rajeshvkothari"
git config --global user.email "53209625+rajeshvkothari@users.noreply.github.com"
git config --global user.name "rajeshvkothari"
git config --global gitreview.username rajeshvkothari

--------------------------------------------------------------------------------

for remove image from vm:
docker rmi {IMAGE ID}

For delete image:
docker rmi 172.31.27.186:5000/tosca-gawp:26-Jan-2024

DELETE /v2/tosca-gawp:26-Jan-2024/manifests/172.31.27.186:5000

http://18.222.131.67:5000/v2/ubuntu/tags/list
