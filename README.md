<h1>GIN</h1>

<h2>Table of contents</h2>

<!--ts-->
- [Introduction](#introduction)
- [Setup GIN](#setup-gin)
  - [Create and Deploy new BOOTSTRAP and cci-gin servers](#create-and-deploy-new-bootstrap-and-cci-gin-servers)
  - [Create and Deploy cci-gin server using existing BOOTSTRAP server](#create-and-deploy-cci-gin-server-using-existing-bootstrap-server)
- [cci-gin Server Deployment Verification Steps](#cci-gin-server-deployment-verification-steps)
  - [cci-gin Server Description](#cci-gin-server-description)
  - [Validate cci-gin Server Deployment](#validate-cci-gin-server-deployment)
  - [Verify Certificates In cci-gin Components](#verify-certificates-in-cci-gin-components)
  - [cci-gin GUI Verification](#cci-gin-gui-verification)
  - [Validate Deployment After Restarting cci-gin Server](#validate-deployment-after-restarting-cci-gin-server)
- [TOSCA Models](#tosca-models)
  - [Types Of Models](#types-of-models)
  - [Models Available In gin](#models-available-in-gin)
  - [Copy CSARs](#copy-csars)
- [Deployment Of TOSCA Models](#deployment-of-tosca-models)
  - [Common Steps](#common-steps)
  - [Tick Based Models](#tick-based-models)
    - [dcaf-cmts Model](#dcaf-cmts-model)
    - [dcaf4 Model](#dcaf4-model)
    - [dcaf3 Model](#dcaf3-model)
    - [dcaf2 Model](#dcaf2-model)
    - [dcaf Model](#dcaf-model)
    - [tickclamp2 Model](#tickclamp2-model)
    - [tickclamp Model](#tickclamp-model)
  - [sdwan Model](#sdwan-model)
  - [o-ran Models](#o-ran-models)
    - [nonrtric-cherry Model](#nonrtric-cherry-model)
    - [nonrtric Model](#nonrtric-model)
    - [ric2-grelease](#ric2-grelease)
    - [ric2](#ric2)
    - [qp2, qp-driver2 and ts2](#qp2-qp-driver2-and-ts2)
- [Clean Environment](#clean-environment)
- [Troubleshooting](#troubleshooting)

<!--te-->

## Introduction

This README is a user guide that describes how various components of GIN need to be set up and used.

## Setup GIN

**IMPORTANT NOTE 1**: *While setting up cci-gin server through terraform script or through ansible playbook, if **enable_ssl** is set to **true**, then trusted certificates for gin dashboards and apisix-gateway get used. If **enable_ssl** is set to **false**, then self-signed certificates (also known as Staging certificates) will be used and the connections will be unsecure. Since there are a limited number of trusted certificates provided by Lets encrypt, set **enable_ssl** to **false** for setting up server for testing. Set it to **true** only if server is to be setup for demo to customer.*

**To setup cci-gin server there are following options:**

### Create and Deploy new BOOTSTRAP and cci-gin servers

  **NOTE**: *Use these steps from any ubuntu machine or from WSL(ubuntu 18.04) in a Windows machine.*

  - Start **CCI-REPO** VM in AWS Ohio region if it is not already in running state.

    - Clone gin-ansible
  
      ```sh
      $ git clone https://github.com/customercaresolutions/gin-ansible --recurse-submodules
      
      NOTE: To deploy a specific release of cci-gin server, add '-b {tagName}' as a parameter in above command.
          e.g.
           git clone https://github.com/customercaresolutions/gin-ansible --recurse-submodules -b v1.4.8
      ```

      Currently, latest tag of gin-ansible is v1.4.8.

    - Copy **cciPrivateKey** file to **gin-ansible/bootstrap/resources** directory.

    - Run following commands to setup tools required for running a terraform script :

      ```sh
      $ cd /home/ubuntu/gin-ansible/bootstrap
      $ chmod u=rwx,g=r,o=r setup.sh
      $ sed -i -e 's/\r$//' setup.sh
      $ ./setup.sh
      ```
    
      **NOTE**: *Above steps need to be executed only once on a given bootstrap server. There is no need to run these steps again for eg after restart or at any other time.*

    - Deploy **GIN-BOOTSTRAP-0 (which in turn creates and sets up cci-gin server)** server using terraform :

      ```sh
      $ cd /home/ubuntu/gin-ansible/bootstrap
      $ terraform init

      # Provide command line argument values as follows:
      #  . git username in place of 'USERNAME_OF_GIT' 
      #  . git token in place of 'TOKEN_OF_GIT'.
      #  . unique AWS instance name in place of 'NAME_OF_AWS_INSTANCE' (eg: gin).
      #  . AWS domain name in place of 'DOMAIN_NAME' (eg: cci-dev.com). 
      #  . set enable_ssl to true to use trusted certificates. Set it to false for using self-signed (untrusted) certificates. Use true only for customer demo.
      #  . provide service_mesh=linkerd to use linkerd service mesh in GIN. For using istio provide service_mesh=istio

      $ terraform apply -var "github_user={USERNAME_OF_GIT}" -var "github_token={TOKEN_OF_GIT}" -var "aws_instance_name={NAME_OF_AWS_INSTANCE}" -var "domain_name={DOMAIN_NAME}" -var "enable_ssl=false" -var "service_mesh=linkerd" -auto-approve
      ```

      Above terraform command takes approximately 20-25 minutes. This command creates and sets up **GIN-BOOTSTRAP-0** server which, in turn, creates and sets up **cci-gin** server (with a name given in NAME_OF_AWS_INSTANCE parameter) in AWS Ohio region. The **cci-gin** server deployment can be verified using steps given in subsequest sections.

### Create and Deploy cci-gin server using existing BOOTSTRAP server
 
  - Deploy **cci-gin** server using ansible :

    ```sh
    cd /opt/app/gin-deployments/gin-ansible

    # Run following step when running the ansible playbook at first time or after restarting the bootstrap server. 
    source /opt/app/gin-deployments/gin-ansible/common/launch_vault.sh
    eval `ssh-agent -s` 
    ssh-add /home/ubuntu/.ssh/cciPrivateKey

    # Provide command line argument values as follows:
    #  . unique AWS instance name in place of 'NAME_OF_AWS_INSTANCE' (eg: gin).
    #  . AWS domain name in place of 'DOMAIN_NAME' (eg: cci-dev.com). 
    #  . set enable_ssl to true to use trusted certificates. Set it to false for using self-signed (untrusted) certificates. Use true only for customer demo.
    #  . provide service_mesh=linkerd to use linkerd service mesh in GIN. For using istio provide service_mesh=istio

    ansible-playbook install_gin-tf.yml -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars  "aws_instance_name={NAME_OF_AWS_INSTANCE} domain_name={DOMAIN_NAME} enable_ssl=false service_mesh=linkerd" --vault-password-file=vault-pwd.txt
      
	```

    Above ansible playbook command takes approximately 20-25 minutes and creates and sets up **cci-gin** server in AWS Ohio region which can be verified using steps given in subsequent sections.

## cci-gin Server Deployment Verification Steps

### cci-gin Server Description

GIN is a set of tools for stateless cloud topology management and deployment based on TOSCA. The **cci-gin** server consists of following components :

- K3s :
  
   K3s is a lightweight kubernetes deployment binary which reduces the ‘heavily loaded’ k8s deployment. **cci-gin** server uses k3s for setting up all its components.
  
- Helm :

  Helm is used to manage kubernetes applications. Helm charts are used to define, install, and upgrade kubernetes applications. Helm is used to find, share, and use software built for kubernetes. Deployment of **cci-gin** is done using helm charts.

- APISIX :

  Apache APISIX is used to set up routes to connect to GIN services. When a request arrives at APISIX, it forwards it to the correct service based on routes already set up by the user.  APISIX creates routes at the time of initialization of tosca-so and tosca-compiler GIN pods.

- Istio :

  Istio is a service mesh used for traffic management, telemetry, metrics, tracing and security in **cci-gin**.

- Linkerd :

  Linkerd is an ultralight, security-first service mesh for Kubernetes. Linkerd adds critical security, observability, and reliability features to Kubernetes stack in **cci-gin**.

- Kiali :

  Kiali is an observability console for Istio with service mesh configuration and validation capabilities. Several other dashboards such as **Argo, Kubernetes, TOSCA Models**, and **Chronograf** have been integrated in kiali.

- DMaaP :

  DMaaP is a ONAP component which is used in GIN for event management. TOSCA-SO, TOSCA-GAWP and TOSCA-POLICY use DMAAP for exchanging events. Structure of events is defined using **cloudevent** and DMAAP producer and subscriber are based on **watermill**.

- Reposure :

  Reposure is used as a registry for saving and accessing tosca model csars.

- Argo :

  Argo Server executes Argo workflows which is an opensource container-native workflow engine for orchestrating parallel jobs on kubernetes.

- Traefik :

  Traefik is a HTTP reverse proxy. Traefik uses **Let's Encrypt** for managing trusted certificates in GIN components.

- Authelia : 
 
  Authelia is an open-source authentication and authorization server which provides single sign-on (SSO) for GIN dashboards via a web portal.

### Validate cci-gin Server Deployment

- Go to **kubernetes-dashboard** select namespace "gin" and check that all GIN pods are in running state :

    ```sh
      NAME                                    READY   STATUS      RESTARTS   AGE
      tick-influx-influxdb-0                  2/2     Running     0          49m
      tick-tel-telegraf-7d9fd577bc-pz682      2/2     Running     0          49m
      tick-kap-kapacitor-7b97f866f7-62kzd     2/2     Running     0          49m
      tick-chron-chronograf-5df5cd87f-mt9jz   2/2     Running     0          49m
      zookeeper-85fbfbb49f-jpbvt              2/2     Running     0          49m
      kafka111-7746747c8d-njrxz               2/2     Running     0          49m
      dmaap-5bddfd7f4b-6jmb6                  2/2     Running     0          48m
      minio-74d9d98bbb-vfxbg                  2/2     Running     0          40m
      svclb-argo-server-bcmwg                 2/2     Running     0          40m
      postgres-77dc5db9d4-8wxxw               2/2     Running     0          40m
      workflow-controller-847654dd4d-6qxkl    2/2     Running     3          40m
      argo-server-67dc857958-dwnvc            2/2     Running     3          40m
      dgraph-1665640391-dgraph-ratel-7f888f6  2/2     Running     0          24m
      dgraph-1665640391-dgraph-alpha-0        2/2     Running     0          24m
      dgraph-1665640391-dgraph-zero-0         2/2     Running     0          24m
      gin-tosca-policy-69dff465fb-ndhng       3/3     Running     2          24m
      gin-tosca-gawp-578df57756-pz2z7         3/3     Running     2          24m
      gin-tosca-so-7786d6569d-hx6sp           3/3     Running     2          24m
      gin-tosca-workflow-df75fcb76-7tnzd      3/3     Running     2          24m
      gin-tosca-compiler-7f64b455f-k5w5x      3/3     Running     2          24m
      jaeger-all-in-one-0                     2/2     Running     0          24m
    ```
  
- Go to **kubernetes-dashboard** select namespace "cert-manager" and check that all cert-manager pods are in running state :

    ```sh
      NAME                                       READY   STATUS    RESTARTS   AGE
      cert-manager-cainjector-5bcf77b697-lsps8   1/1     Running   0          10m
      cert-manager-57d89b9548-9pjrt              1/1     Running   0          10m
      cert-manager-webhook-9cb88bd6d-blqjd       1/1     Running   0          10m
      cert-manager-istio-csr-67b8b4d677-8k645    1/1     Running   0          9m9s
    ```

- Go to **kubernetes-dashboard** select namespace "ingress-apisix" and check that all apisix pods are in running state :

    ```sh
      NAME                                         READY   STATUS    RESTARTS   AGE
      apisix-etcd-0                                1/1     Running   0          5m5s
      apisix-etcd-2                                1/1     Running   0          5m5s
      apisix-etcd-1                                1/1     Running   0          5m5s
      apisix-577dd8f79-jwn2c                       1/1     Running   0          5m5s
      apisix-dashboard-796964cccd-s92tc            1/1     Running   0          114s
      svclb-apisix-dashboard-xztnv                 1/1     Running   0          106s
      apisix-ingress-controller-56cf45c658-fpxxr   1/1     Running   0          5m5s
    ```
    
- Go to **kubernetes-dashboard** select namespace "auth" and check that all authelia pods are in running state : 
    
    ```sh
      NAME                        READY   STATUS    RESTARTS   AGE
      authelia-7d6788b44f-s9tvj   1/1     Running   0          76m
    ```

- Go to **kubernetes-dashboard** select namespace "default" and check that all reposure and traefik pods are in running state : 
     
    ```sh
      NAME                                 READY   STATUS    RESTARTS   AGE
      reposure-operator-86c454d9c4-96cgf   2/2     Running   0          80m
      reposure-simple-6f556759ff-szx4q     2/2     Running   0          79m
      reposure-surrogate-default           2/2     Running   0          79m
      svclb-traefik-8lvsq                  3/3     Running   0          78m
      traefik-77dfc649f-7st69              2/2     Running   0          78m
    ```

### Verify Certificates In cci-gin Components

  **IMPORTANT NOTE:** Following steps should be used only if istio service mesh is used (they are not relevant for linkerd service mesh). 

- To validate that istio-proxy sidecar container has requested the certificate from the correct service, check the container logs:

  ```sh
  kubectl logs $(kubectl get pod -n gin -o jsonpath="{.items...metadata.name}" --selector app=tosca-compiler ) -c istio-proxy -n gin | head -n 50 
  ```
  
  Initial logs should include following :
  
  ```text
  2022-03-09T09:46:01.832611Z     info    CA Endpoint cert-manager-istio-csr.cert-manager.svc:443, provider Citadel
  2022-03-09T09:46:01.832750Z     info    Using CA cert-manager-istio-csr.cert-manager.svc:443 cert with certs: var/run/secrets/istio/root-cert.pem
  2022-03-09T09:46:01.832840Z     info    citadelclient   Citadel client using custom root cert: cert-manager-istio-csr.cert-manager.svc:443
  ```
  
- Verify that the certificate is used by Envoy :

  ```sh
  istioctl proxy-config secret $(kubectl get pods -n gin -o jsonpath='{.items..metadata.name}' --selector app=tosca-compiler) -n gin -o json | jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode | openssl x509 -text -noout
  ```

  ```text
  Certificate:
      Data:
        Version: 3 (0x2)
          Serial Number:
            6e:5f:58:b9:92:ea:e8:e8:7d:9f:5e:8b:25:b6:63:8f
          Signature Algorithm: ecdsa-with-SHA256
          Issuer: O = cert-manager + O = cluster.local, CN = istio-ca
          Validity
            Not Before: Mar  9 09:46:02 2022 GMT
            Not After : Mar  9 10:46:02 2022 GMT
        ...
          X509v3 Subject Alternative Name:
            URI:spiffe://cluster.local/ns/gin/sa/default
  ```

### cci-gin GUI Verification

- **Kiali GUI** :

  This GUI can be used to verify and monitor **cci-gin** deployment.
  
  Use following URL to open kiali GUI from local machine browser :

  ```sh
  https://{NAME_OF_AWS_INSTANCE}-kiali.{DOMAIN_NAME}/kiali
  # e.g: https://gin-kiali.cci-dev.com/kiali
  ```

  **IMPORTANT NOTE:** Kiali GUI will redirect to Authelia for authentication. Use following credentials to login into Authelia. 

  ```text
  Username : admin
  Password : admin
  ```
  
  This opens kiali GUI which includes dashboards for various GIN components.
  
- **Kubernetes-dashboard GUI** :

  After opening kiali GUI, click on **kubeDashboard** tab.

  **Note :** A token value ```admin``` is required to login into kubernetes dashboard.

  From **kubeDashboard**, verify that following namespaces have been created: **gin**, **cert-manager**, **ingress-apisix**, **istio-system**(only for istio based setup) and **auth**.

- **APISIX GUI** :

  After opening kiali GUI, click on **APISIX** tab.
  
  Use following credentials to access APISIX GUI

  ```text
  Username : admin
  Password : admin
  ```  

  After opening APISIX GUI, go to the **route** tab and verify that two routes **tosca-so** and **tosca-compiler** have been created.

- **Argo GUI** :

  This GUI is to be used after deploying a model.

  After opening argo GUI, click on the **workflow** which bears a name starting with the **instance** name provided while creating the model service instance.

  This will display workflow steps in tree format. If the model is deployed successfully, then it will show a **right tick** symbol with green background for all the steps.

- **Grafana Loki GUI** :

  After opening kiali GUI, click on **Grafana Loki** tab.

  Use following credentials to access Grafana Loki GUI :
  ```text
  Username : admin
  Password : admin123
  ```
 
  To see logs of any given GIN service, go to **Explore** tab and search for that service.

- **Linkerd GUI** :

  For accessing Linkerd GUI, click on **Linkerd** tab in kiali GUI.

- **Dgraph GUI** :

  This GUI is to be used after uploading a model in TOSCA GUI.
  
  After opening kiali GUI, click on **Dgraph** tab.   
  
  Select **Launch Latest** then click on **Dgraph Server Connection** and Add following url in **Dgraph server URL** field :

  ```sh
   https://{NAME_OF_AWS_INSTANCE}-alpha.{DOMAIN_NAME}

   e.g.
   https://gin-alpha.cci-dev.com
  ```

   Then click on **connect** => **continue**

- **Jaeger/Distributed Tracing GUI** :

  This GUI is to be used after deploying a model.
  
  After opening kiali GUI, click on **Distributed Tracing** tab.

  After deployment of any model, see **tracing graph** of any given microservice in Jaeger GUI.

- **Chronograf GUI** :

  This GUI is to be used after deploying a model.
  
  After opening kiali GUI, click on **Chronograf** tab.

  - Click on **Get Started**.
  - Replace Connection URL **http://localhost:8086** with **http://tick-influx-influxdb:8086** and also give connection name as Influxdb.
  - Select the pre-created Dashboard e.g System, Docker, etc.
  - Replace Kapacitor URL **http://tick-influx-influxdb:9092/** with **http://tick-kap-kapacitor:9092/** and give the name as Kapacitor.
  - Click on **Continue** and in the next step click on **View all connections**.
  
- **TOSCA Models GUI** :

   This tab is used for uploading and visualizing TOSCA models.

   After opening kiali GUI, click on the **TOSCA Models** tab.

- **TOSCA Deployments GUI** :

   This tab is used for creating/monitoring and deleting instances of TOSCA models which have been previously uploaded using TOSCA Models GUI.

### Validate Deployment After Restarting cci-gin Server

  - **cci-gin** server can be stopped and restarted as and when required. 
  
  - After restarting **cci-gin** server, wait for 5 minutes to ensure that all the pods come up. Use following steps to validate deployment:
    
    - [Validate **cci-gin** Server Deployment](#Validate-cci-gin-Server-Deployment)

    - [Verify Certificates In **cci-gin** Components](#Verify-Certificates-In-cci-gin-Components)

    - [**cci-gin** GUI Description](#cci-gin-GUI-Verification)
  
  
  - If apisix pods are still not in Running state, use following to restart APISIX and TOSCA services :

    ```sh
    $ cd /home/ubuntu/gin-util/apisix
    $ ./apisix-restart.sh
    ```

     Wait for 5 minutes after running the above and verify that apisix and GIN pods are in Running state.

## TOSCA Models

### Types Of Models
  
- Single workflow container :

  Workflow steps are executed sequentially in single container.

  - **tickclamp2** (Including its dependencies - **helm, ves-collector, tick-cluster**)

- Multiple workflow container :

  Workflow steps are executed in parallel in multiple containers.
  
  - **dcaf-cmts** (Including its dependencies - **cluster, cluster-resource, dcaf-resource**)
  - **dcaf4** (Including its dependencies - **cluster, cluster-resource, dcaf-resource, ves-collector**)
  - **dcaf3** (Including its dependencies - **cluster, dcaf-resource, ves-collector**)
  - **dcaf2** (Including its dependencies - **helm, dcaf-resource, ves-collector**)
  - **dcaf** (Including its dependencies - **ves-collector**)
  - **tickclamp**
  - **sdwan** (Including its dependencies - **sdwan-resource**)
  - **o-ran**

### Models Available In gin
  
- TICK based models :

    <table>
     <thead>
      <tr>
       <th rowspan="2">Features</th>
       <th colspan="6" style="text-align: center" >Models</th>
      </tr>
      <tr>
       <th>dcaf-cmts</th>
       <th>dcaf4</th>
       <th>dcaf3</th>
       <th>dcaf2</th>
       <th>dcaf</th>
       <th>tickclamp2</th>
    <th>tickclamp</th>
      </tr>
     <thead>
     <tbody>
      <tr>
       <td>Summary</td>
       <td>This model uses original TICK components, remote helm charts and tick profile. Also it depends on "cluster", "cluster-resource" and "dcaf-resource" models. Policy execution happens through policy microservice.</td>
       <td>This model uses original TICK components, remote helm charts and tick profile. Also it depends on "cluster", "cluster-resource", "ves-collector" and "dcaf-resource" models. Policy execution happens through policy microservice.</td>
       <td>This model uses original TICK components, remote helm charts and tick profile. Also it depends on "cluster", "ves-collector" and "dcaf-resource" models. Policy execution happens through Policy microservice.</td>
       <td>This model uses original TICK components, remote helm charts and tick profile. Also it depends on "helm", "ves-collector" and "dcaf-resource" models. Policy execution happens through Policy microservice.</td>
       <td>This model uses original TICK components. But this model uses "ves-collector". Policy execution happens through Policy microservice.</td>
       <td>It uses original TICK components. But it takes helm charts of TICK from remote locations. Also this model has dependencies on "helm" and "tick-cluster" models. Policy execution happens directly using kapacitor.</td>
    <td>This model uses original TICK components. Policy execution happens directly using kapacitor.</td>
      </tr>
      <tr>
       <td>Type of workflow container</td>
       <td>Multi Container</td>
       <td>Multi Container</td>
       <td>Multi Container</td>
       <td>Multi Container</td>
       <td>Multi Container</td>
       <td>Single Container</td>
    <td>Multi Container</td>
      </tr>
      <tr>
       <td>Dependency on other model(s) based on req/cap</td>
       <td>No</td>
       <td>No</td>
       <td>No</td>
       <td>Yes (helm)</td>
       <td>No</td>
       <td>Yes (helm)</td>
    <td>No</td>
      </tr>
      <tr>
       <td>Dependency on other model(s) based on select directive</td>
       <td>Yes(cluster (cluster-resource))</td>
       <td>Yes(cluster (cluster-resource), ves-collector)</td>
       <td>Yes(cluster, ves-collector)</td>
       <td>Yes(ves-collector)</td>
       <td>Yes(ves-collector)</td>
       <td>Yes(tick-cluster)</td>
    <td>No</td>
      </tr>
      <tr>
       <td>Use of substitution mapping within same model</td>
       <td>Yes</td>
       <td>Yes</td>
       <td>No</td>
       <td>No</td>
       <td>Yes</td>
       <td>No</td>
    <td>Yes</td>
      </tr>
      <tr>
       <td>Use of substitute directive with another model</td>
       <td>Yes(dcaf-resource)</td>
       <td>Yes(dcaf-resource)</td>
       <td>Yes(dcaf-resource)</td>
       <td>Yes(dcaf-resource)</td>
       <td>No</td>
       <td>No</td>
    <td>No</td>
      </tr>
      <tr>
       <td>Fetch helm charts from remote location</td>
       <td>Yes</td>
       <td>Yes</td>
       <td>Yes</td>
       <td>Yes</td>
       <td>No</td>
       <td>Yes</td>
    <td>No</td>
      </tr>
      <tr>
       <td>Use of TICK profile</td>
       <td>Yes</td>
       <td>Yes</td>
       <td>Yes</td>
       <td>No</td>
       <td>No</td>
    <td>No</td>
      </tr>
      <tr>
       <td>Argo display</td>
       <td>Displays full hierarchy of steps and they are run in parallel in multiple containers.</td>
       <td>Displays full hierarchy of steps and they are run in parallel in multiple containers.</td>
       <td>Displays full hierarchy of steps and they are run in parallel in multiple containers.</td>
       <td>Displays full hierarchy of steps and they are run in parallel in multiple containers.</td>
       <td>Displays full hierarchy of steps and they are run in parallel in multiple containers.</td>
       <td>Displays steps linearly and they are run sequentially in single container.</td>
    <td>Displays full hierarchy of steps and steps are run in parallel in multiple containers.</td>
      </tr>
     </tbody>
    </table>

- **sdwan** :

  **sdwan** is the model which creates a secure tunnel between two VMs which are deployed on N.Virginia region of AWS after deployment of **sdwan** model.

- **o-ran** :
    <table>
     <thead>
      <tr>
       <th rowspan="2">Features</th>
       <th colspan="9" style="text-align: center">Models</th>
      </tr>
      <tr>
       <th>nonrtric</th>
       <th>nonrtric-cherry</th>
       <th>ric2</th>
       <th>ric2-grelease</th>
       <th>qp2</th>
       <th>qp-driver2</th>
       <th>ts2</th>
      </tr>
     <thead>
     <tbody>
      <tr>
       <td>Type of workflow container</td>
       <td colspan="9" style="text-align: center">Multi Container</td>
      </tr>
      <tr>
       <td>Dependency on other model(s) based on select directive</td>
       <td>No</td>
       <td>No</td>
       <td>Yes (cluster)</td>
       <td>Yes (cluster)</td>
       <td>Yes (cluster)</td>
       <td>Yes (cluster)</td>
       <td>Yes (cluster)</td>
      </tr>
      <tr>
       <td>Argo display</td>
       <td colspan="9" style="text-align: center">Displays full hierarchy of steps and steps are run in parallel in multiple containers.</td>
      </tr>
     </tbody>
    </table>

### Copy CSARs

This section contains steps to copy tosca models csars from **cci-gin** server to **local machine**.

- The latest CSARs for all the models are available in **csars** folder in **tosca-models** repository.
Copy them to local machine so that they can be uploaded using TOSCA Models GUI.
  
## Deployment Of TOSCA Models

This section contains steps to deploy tosca models.
  
### Common Steps

- Use TOSCA-Models GUI to upload models from local machine to database. This GUI has following functions :

  - **List** : List is used to list models which are saved in the database.
  
  - **Upload** : Upload is used to upload a model CSAR from local machine and save it in database. It also update Visualizer part of GUI with display of uploaded model's nodes in graph format.

    **IMPORTANT NOTE** : *While saving a model in database, if its dependencies are not saved, error/warning conditions will be flagged. **e.g.** If  ***dcaf4*** saved without saving its one or more of its dependencies such as ***cluster, dcaf-resource*** and ***ves-collector***, it will result in warning*.

  - **Delete** : Delete is used to delete selected model from the database.

  - **Show Details** : Show Details is used to show detailed information in graph like names of edges, full names of nodes etc.

  - **Clear** : Clear is used to clear model's node graph from Visualizer part of GUI. Note that this does not affect model database.

- Use **TOSCA-Deployment** GUI tab in kiali GUI to create a service instance of a model which has been uploaded. This GUI shows two tabs -- one for deployable models and other for deployed instances. To deploy an instance of a model, use following steps:
 
  - Click on 'Models' tab and select the model to deploy. After selecting the model, input parameters will be displayed.
	
  - Provide required inputs which will be shown inside Red color box. 
  
  - Click on **deploy** button at bottom to deploy instance.

  - After deploying instance(s), click on **Instances** tab to see list of deployed instances. Click on instance to see details like instance **deployment status, output data**, etc.

  - To delete an instance, click on **delete** button.

### Tick Based Models

**IMPORTANT NOTE** : *There are some restrictions on models that may be deployed simultaneously. For example, **dcaf, dcaf2, dcaf3**, **dcaf4** and **dcaf-cmts** can not be deployed simultaneously. Similarly, **tickclamp** and **tickclamp2** can not be deployed simultaneously.*


#### dcaf-cmts Model
   
  **Note :** *While deploying **dcaf-cmts** model instance, instances of all its dependencies **(cluster, cluster-resource, dcaf-resource)** get created automatically.*

    Following required inputs need to be filled in
    
    - dcaf-cmts 
      
	    ```sh
	    Instance Name = {name_of_instance}
	    ```
	  
      - cluster
	
	      Note: No need to provide input for cluster model
	  
        - cluster-resource
	        
          ```sh
          cluster_name = dcaf
          ```
	      
      - dcaf-resource
        
        ```sh
	      k8scluster_name = dcaf
        ```
	  
  - After deploying the model, use Argo GUI tab in Kiali which shows workflow execution progress.

  - Go to **kubernetes-dashboard** select namespace "dcaf" and check that all dcaf pods are in running state : 

      ```sh
      NAME                                     READY    STATUS    RESTARTS   AGE
      tick-influx-influxdb-0                     1/1     Running   0          7m21s
      kapacitor-filter-5bf744d4-h6w9w            1/1     Running   0          6m3s
      tick-kap-kapacitor-5cd49b877b-qwjf7        1/1     Running   0          5m3s
      tick-tel-telegraf-75c54444fc-vnpf7         1/1     Running   0          4m3s
      tick-chron-chronograf-8665458cd4-fftdp     1/1     Running   0          6m3s
      e6000-6fdf97977-hrzg5                      1/1     Running   0          5m45s
      ```
        
  - Check rate in **chronograf** go to **kiali-dashboard** and click on **TOSCA-deployement** then click on **instances**. after select instance it will show **deployment status, output data**. get the **ChronografUrl** from **output data**
     
	  ```sh
       # e.g: ChronografUrl= http://23.124.125.320:32153
      ```
      
      After opening **chronograph** GUI click on **Dashboard** tab. Then select **DCAF** dashboard. This will show rate. Currently policy execution is not fully supported by dcaf-cmts model.


#### dcaf4 Model
   
  **Note :** *While deploying **dcaf4** model instance, instances of all its dependencies **(cluster, cluster-resource, dcaf-resource and ves-collector)** get created automatically.*

    Following required inputs need to be filled in
    
    - dcaf4 
      
	    ```sh
	    Instance Name = {name_of_instance}
	    ```
	  
      - cluster
	
	      Note: No need to provide input for cluster model
	  
        - cluster-resource
	        
          ```sh
          cluster_name = dcaf
          ```
	      
      - dcaf-resource
        
        ```sh
	      k8scluster_name = dcaf
        ```
	      
      - ves-collector
	        
        ```sh
	      k8scluster_name = dcaf
	      ```
	  
  - After deploying the model, use Argo GUI tab in Kiali which shows workflow execution progress.

  - Go to **kubernetes-dashboard** select namespace "dcaf" and check that all dcaf pods are in running state : 

      ```sh
      NAME                                     READY    STATUS    RESTARTS   AGE
      ves-collector-7b57969c6f-dwdcd             1/1     Running   0          6m21s
      tick-influx-influxdb-0                     1/1     Running   0          7m21s
      kapacitor-filter-5bf744d4-h6w9w            1/1     Running   0          6m3s
      tick-kap-kapacitor-5cd49b877b-qwjf7        1/1     Running   0          5m3s
      tick-tel-telegraf-75c54444fc-vnpf7         1/1     Running   0          4m3s
      tick-chron-chronograf-8665458cd4-fftdp     1/1     Running   0          6m3s
      tick-client-gintelclient-6fdf97977-hrzg5   1/1     Running   0          5m45s
      ```
        
  - Check policy execution in **chronograf** go to **kiali-dashboard** and click on **TOSCA-deployement** then click on **instances**. after select instance it will show **deployment status, output data**. get the **ChronografUrl** from **output data**
     
	  ```sh
       # e.g: ChronografUrl= http://23.124.125.320:32153
      ```
      
      After opening **chronograph** GUI click on **Dashboard** tab. Then select **DCAF** dashboard. This will show policy execution graph.

	
#### dcaf3 Model

  **Note :** *While deploying **dcaf3** model instance, instances of all its dependencies **(cluster, dcaf-resource and ves-collector)** get created automatically.*
	
  - Following required inputs need to be filled in
	
	Note : The required inputs will gets shown in red box. After fill inputs click on **deploy** button at bottom to deploy instance.
  
	- dcaf3
 
	  ```sh
	  Instance Name = {name_of_instance}
	  ``` 
	  - cluster
	  
	    Note: No need to provide input for cluster model
		
	    - cluster-resource
	      
        ```sh
	      cluster_name = dcaf
        ```
	   
      - dcaf-resource
  		   
        ```sh
  	    k8scluster_name = dcaf
        ```
  	  
      - ves-collector
  	    
        ```sh
  	    k8scluster_name = dcaf
  	    ```

  - After request for deploying the model has been submitted, use Argo GUI tab in Kiali which shows workflow execution progress.
  
  - Go to **kubernetes-dashboard** select namespace "dcaf" and check that all dcaf pods are in running state same as dcaf4.
  
  - Check policy execution in **chronograf**

    Use following command on **cci-gin** server to obtain external port of chronograf service:
	
      ```sh
      $ kubectl get svc tick-chron-chronograf -n dcaf
      NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
      tick-chron-chronograf   NodePort   10.43.166.128   <none>        80:32153/TCP   7m46s
      ```

    Use following URL to open kiali GUI from local machine browser :

    **Note** : *Use external port of **tick-chron-chronograf** service in place of **CHRONOGRAF_SERVICE_PORT***
    ```sh
    http://{PUBLIC_IP_OF_CCI_GIN_SERVER}:{CHRONOGRAF_SERVICE_PORT}

    # e.g: http://23.124.125.320:32153
	```
	
  - After opening **chronograph** GUI use following steps to check graph:

    - Click on **Get Started**.
    - Replace Connection URL **<http://localhost:8086>** with **<http://tick-influx-influxdb:8086>** and also give connection name to Influxdb.
    - Select the pre-created Dashboard e.g System, Docker, etc.
    - Replace Kapacitor URL **<http://tick-influx-influxdb:9092/>** with **<http://tick-kap-kapacitor:9092/>** and give the name to Kapacitor.
    - Click on **Continue** and In the next step click on **View all connections**.
    - then, click on **alerting** and check policy graph

    - Go to explore tab for more information about policy.

    - In **Query1** section copy the following query and then click on **Submit Query**:

       ```sh
       SELECT mean("event_measurementsForVfScalingFields_vNicPerformanceArray_0_receivedTotalPacketsAccumulated") AS "mean_event_measurementsForVfScalingFields_vNicPerformanceArray_0_receivedTotalPacketsAccumulated" FROM "test"."autogen"."http" WHERE time > :dashboardTime: AND time < :upperDashboardTime: GROUP BY time(:interval:) FILL(null)
       ```

    - Then the graph gets visible as an output on the same tab.

  - To clean up **dcaf3** model's deployment use following commands on **cci-gin** server :
    
      ```sh
      kubectl delete ns dcaf
      kubectl delete clusterrole tick-kap-kapacitor-clusterrole-dcaf
      kubectl delete clusterrolebinding tick-kap-kapacitor-clusterrolebinding-dcaf
      ```
	
#### dcaf2 Model

  **Note :** *While deploying **dcaf2** model instance, instances of all its dependencies **(tick-cluster, dcaf-resource and ves-collector)** gets created automatically.*

  - Following required inputs need to be filled in

    Note : The required inputs will gets shown in red box. After fill inputs click on **deploy** button at bottom to deploy instance.
  
    - dcaf2
	     
      ```sh
	    Instance Name = {name_of_instance}
	    ```
	  
      - dcaf-resource
        ```sh
  	    k8scluster_name = dcaf
  	    ```
  	  
      - helm
  
  		  ```sh
        helm_version = 3.5.2
    	  ```	  
  	  
      - ves-collector
  	    ```sh
  	    k8scluster_name = dcaf
        ```
		
  - Go to **kubernetes-dashboard** select namespace "dcaf" and check that all dcaf pods are in running state same as dcaf4.

  - To check policy execution in **chronograf** use same steps as ***dcaf3*** model.

  - To clean up **dcaf2** model's deployment use same steps as **dcaf3*** model.
  

#### dcaf Model
  
  **Note :** *While deploying **dcaf** model instance, an instance of its dependency **(ves-collector)** gets created automatically.*
 
  - Following required inputs need to be filled in		
  
	- dcaf  
	  
    ```sh
	  Instance Name = {name_of_instance}
	  k8scluster_name = dcaf
    ```
	  
    - ves-collector
	    
      ```sh
	    k8scluster_name = dcaf
      ```
      
  - Go to **kubernetes-dashboard** select namespace "dcaf" and check that all dcaf pods are in running state same as dcaf4.
  
  - To check policy execution in **chronograf** use same steps as ***dcaf3*** model.
 
  - To clean up **dcaf** model's deployment use same steps as **dcaf3*** model.


#### tickclamp2 Model

  **Note :** *While deploying **tickclamp2** model instance, instances of all its dependencies **(helm and tick-cluster)** gets created automatically.*
 
  - Following required inputs need to be filled in
    
	  - tickclamp2  	    
	   
      ```sh
      Instance Name = {name_of_instance}
      k8scluster_name = tick
      helm_version = 3.5.2
  	  ```
	  
      - helm
  	    
        ```sh
        helm_version = 3.5.2
    	  ```
  	  
      - tick-cluster	
  		  
        ```sh
        cluster_name = tick
        region_name = us-east-2
        cloud_provider = aws
        number_of_workers = 1
        ```

  - Go to **kubernetes-dashboard** select namespace "tick" and check that all tick pods are in running state :

      ```sh
      NAME                                        READY   STATUS    RESTARTS   AGE
      tick-tel-telegraf-5b6c78f7c6-sj8dn          1/1     Running   0          14s
      tick-chron-chronograf-8f5966dbd-6fsgm       1/1     Running   0          13s
      tick-influx-influxdb-0                      1/1     Running   0          15s
      tick-kap-kapacitor-5cd49b877b-kz5j9         1/1     Running   0          14s
      tick-client-gintelclient-84c98c4478-dnsw2   1/1     Running   0          12s
      ```

  - Check policy execution in **chronograf**

    Use following command on **cci-gin** server to obtain external port of chronograf service:

      ```sh
      $ kubectl get svc tick-chron-chronograf -n tick
      NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
      tick-chron-chronograf   NodePort   10.43.166.128   <none>        80:32153/TCP   7m46s
      ```

    Use following URL to open kiali GUI from local machine browser :

    **Note** : *Use external port of **tick-chron-chronograf** service in place of **CHRONOGRAF_SERVICE_PORT**.*

      ```sh
      http://{PUBLIC_IP_OF_CCI_GIN_SERVER}:{CHRONOGRAF_SERVICE_PORT}

      # e.g: http://23.124.125.320:32153
      ```

  - After opening **chronograph** GUI use following steps to check graph
	
    - Click on **Get Started**.
    - Replace connection URL **<http://localhost:8086>** with **<http://tick-influx-influxdb:8086>** and also give connection name to Influxdb.
    - Select the pre-created Dashboard e.g System, Docker, etc.
    - Replace kapacitor URL **<http://tick-influx-influxdb:9092/>** with **<http://tick-kap-kapacitor:9092/>** and give the name to Kapacitor.
    - Click on **Continue** and In the next step click on **View all connections**.
    - then, click on **alerting** and check policy graph

    - Go to explore tab to observe policy execution.

    - Select **DB.RetentionPolicy** as **telegraf.autogen**, select **Measurements & Tags** as **test_udp_msg** and select **Fields** as **value**.
    - Then, the query and its graph are visible as an output on the same tab.
    - Click on **Send to Dashboard** to send current graph to Dashboard tab.

  - To clean up **tickclamp** model use following commands :

      ```sh
      kubectl delete ns tick
      kubectl delete clusterrole tick-kap-kapacitor-clusterrole-tick
      kubectl delete clusterrolebinding tick-kap-kapacitor-clusterrolebinding-tick
      ```

#### tickclamp Model

  - Provide following require inputs.	
   
	- tickclamp
	  ```sh
	  Instance Name = {name_of_instance}
	  k8scluster_name = tick
  	  ```
	  
  - Go to **kubernetes-dashboard** select namespace "tick" and check that all tickclamp2 pods are in running state same as tickclamp2.

  - To check policy execution in **chronograf** use same steps as ***tickclamp2*** model.

  - Use clean up steps same as **tickclamp2** model.


### sdwan Model

- Following required inputs need to be filled in
  
  - sdwan	
    ```sh
	Instance Name = {name_of_instance}
  	```
	  
**NOTE :** *Currently the region specified in aws.yaml is US East (N.Virginia)us-east-1*

- Verify whether model deployment is successful :

  ***{SERVICE_INSTANCE_NAME}_SDWAN_Site_A*** and ***{SERVICE_INSTANCE_NAME}_SDWAN_Site_B VMs*** should be created on ***AWS N.Virginia region***.

  - SSH into SDWAN_Site_A VM and run the following command :

     ```sh
     $ ifconfig -a
      ens5: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9001
      inet 172.19.254.33  netmask 255.255.255.0  broadcast 0.0.0.0
      inet6 fe80::4cf:94ff:fe39:30a7  prefixlen 64  scopeid 0x20<link>
      ether 06:cf:94:39:30:a7  txqueuelen 1000  (Ethernet)
      RX packets 139  bytes 25029 (25.0 KB)
      RX errors 0  dropped 0  overruns 0  frame 0
      TX packets 161  bytes 24640 (24.6 KB)
      TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

      lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
      inet 127.0.0.1  netmask 255.0.0.0
      inet6 ::1  prefixlen 128  scopeid 0x10<host>
      loop  txqueuelen 1000  (Local Loopback)
      RX packets 254  bytes 21608 (21.6 KB)
      RX errors 0  dropped 0  overruns 0  frame 0
      TX packets 254  bytes 21608 (21.6 KB)
      TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

      vpp1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.19.1.249  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::476:2dff:fe3c:f8a9  prefixlen 64  scopeid 0x20<link>
        ether 06:76:2d:3c:f8:a9  txqueuelen 1000  (Ethernet)
        RX packets 3  bytes 126 (126.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 40  bytes 2852 (2.8 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

      vpp2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1350
        inet 10.100.0.18  netmask 255.255.255.254  broadcast 0.0.0.0
        inet6 fe80::27ff:fefd:18  prefixlen 64  scopeid 0x20<link>
        ether 02:00:27:fd:00:18  txqueuelen 1000  (Ethernet)
        RX packets 38  bytes 3260 (3.2 KB)
        RX errors 0  dropped 1  overruns 0  frame 0
        TX packets 50  bytes 4164 (4.1 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
     ```
  
     Ping WAN Public IP, LAN Private IP(vpp1), and VxLAN IP(vpp2) of SDWAN_Site_B.

  - SSH into SDWAN_Site_B VM and run the following command :

     ```sh
     $ ifconfig -a
      ens5: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9001
      inet 172.14.254.13  netmask 255.255.255.0  broadcast 0.0.0.0
      inet6 fe80::43f:10ff:fedf:b2b3  prefixlen 64  scopeid 0x20<link>
      ether 06:3f:10:df:b2:b3  txqueuelen 1000  (Ethernet)
      RX packets 322  bytes 38221 (38.2 KB)
      RX errors 0  dropped 0  overruns 0  frame 0
      TX packets 325  bytes 37083 (37.0 KB)
      TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

      lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
      inet 127.0.0.1  netmask 255.0.0.0
      inet6 ::1  prefixlen 128  scopeid 0x10<host>
      loop  txqueuelen 1000  (Local Loopback)
      RX packets 255  bytes 21720 (21.7 KB)
      RX errors 0  dropped 0  overruns 0  frame 0
      TX packets 255  bytes 21720 (21.7 KB)
      TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

      vpp1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.14.1.152  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::4a3:43ff:fe0a:33eb  prefixlen 64  scopeid 0x20<link>
        ether 06:a3:43:0a:33:eb  txqueuelen 1000  (Ethernet)
        RX packets 6  bytes 252 (252.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 63  bytes 4530 (4.5 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

      vpp2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1350
        inet 10.100.0.19  netmask 255.255.255.254  broadcast 0.0.0.0
        inet6 fe80::27ff:fefd:19  prefixlen 64  scopeid 0x20<link>
        ether 02:00:27:fd:00:19  txqueuelen 1000  (Ethernet)
        RX packets 64  bytes 5380 (5.3 KB)
        RX errors 0  dropped 1  overruns 0  frame 0
        TX packets 83  bytes 6698 (6.6 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
     ```

    Ping WAN Public IP, LAN Private IP(vpp1), and VxLAN IP(vpp2) of SDWAN_Site_A.

  - To clean up **sdwan** model, terminate ***{SERVICE_INSTANCE_NAME}_SDWAN_Site_A*** and ***{SERVICE_INSTANCE_NAME}_SDWAN_Site_B*** VMs and its ***vpc***  which are created on the ***N.Virginia region*** of AWS.

### o-ran Models

**NOTE 1 :** *To deploy* ***xapp(qp2, qp-driver2*** *and* ***ts2)*** *models,* ***ric2 or ric2-grelease*** *model needs to be deployed first.*
  
**NOTE 2 :** *Deployment of* ***ric2 or ric2-grelease*** *model will create a new AWS VM in Ohio region with same name given in TOSCA-deployment GUI. xapp models will also get deployed on the same VM.*

#### nonrtric-cherry Model
 
  - Following required inputs need to be filled in
  
    - nonrtric-cherry 
	  ```sh
	  Instance Name = {name_of_instance}
  	  ```
  - Go to **kubernetes-dashboard** select namespace "nonrtric" and check that all nonrtric-cherry  pods are in running state.

      ```sh
      NAME                                    READY   STATUS    RESTARTS   AGE
      orufhrecovery-64c6df786f-wvjvz          1/1     Running   1          12h
      a1-sim-std-1                            1/1     Running   1          12h
      a1-sim-std2-0                           1/1     Running   1          12h
      ransliceassurance-7467d86485-blbj6      1/1     Running   1          12h
      a1-sim-osc-1                            1/1     Running   1          12h
      db-76d79cd769-k58sv                     1/1     Running   1          12h
      rappcatalogueservice-7ff49b88dc-fxp2f   1/1     Running   1          12h
      dmaapadapterservice-0                   1/1     Running   1          12h
      policymanagementservice-0               1/1     Running   1          12h
      informationservice-0                    1/1     Running   1          12h
      a1-sim-std-0                            1/1     Running   1          12h
      helmmanager-0                           1/1     Running   1          12h
      a1-sim-osc-0                            1/1     Running   1          12h
      dmaapmediatorservice-0                  1/1     Running   1          12h
      nonrtricgateway-6b67dbf64f-vzp8h        1/1     Running   1          12h
      a1-sim-std2-1                           1/1     Running   1          12h
      controlpanel-65cdc88bcb-9jwfq           1/1     Running   3          12h
      a1controller-fcb5d4fbc-xdj4l            1/1     Running   1          12h
      ```
    
  - To access **nonrtric-cherry dashboard** go to **kiali-dashboard** and click on **TOSCA-deployement** click on **instances**. select instance from instances list. after, select instance it will show **output data**, get **ControllpanelUrl** from **output data** to access nonrtric-cherry dashboard.

#### nonrtric Model
 
  - Use steps same as ***nonrtric-cherry*** model to deploy nonrtric model
  	  
  - Go to **kubernetes-dashboard** select namespace "nonrtric" and check that all nonrtric  pods are in running state.
 
      ```sh
      NAME                                       READY   STATUS    RESTARTS   AGE
      db-5d6d996454-2r6js                        1/1     Running   0          4m25s
      enrichmentservice-5fd94b6d95-sx9gx         1/1     Running   0          4m25s
      policymanagementservice-78f6b4549f-8skq2   1/1     Running   0          4m25s
      rappcatalogueservice-64495fcc8f-d77m7      1/1     Running   0          4m25s
      a1-sim-std-0                               1/1     Running   0          4m25s
      controlpanel-fbf9d64b6-npcxp               1/1     Running   0          4m25s
      a1-sim-osc-0                               1/1     Running   0          4m25s
      a1-sim-std-1                               1/1     Running   0          2m54s
      a1-sim-osc-1                               1/1     Running   0          2m50s
      a1controller-cb6d7f6b8-m4qcn               1/1     Running   0          4m25s
      ```
	
  - To delete **nonrtric** model deployment go to **kiali-dashboard** and click on **TOSCA-deployement**  click on **instances**. select instance from instances list. after, select instance it will show buttons then click on **delete** button.  
	  
#### ric2-grelease 

  **Note :** *While deploying **ric2-grelease** model instance, an instance of its dependency **(cluster)** gets created automatically.*  

  - Following required inputs need to be filled in
  
	- ric2-grelease 
	  ```sh
	  Instance Name = {name_of_instance}
	  k8scluster_name = ric
  	  ```	  
	  - cluster
        ```sh
		new_cluster = true
		
		# Note: use region_name "us-east-2" only, using other region_name require changes to rest of inputs parameter
		
		region_name = us-east-2
		```
	    - cluster-resource
	      ```sh
	      cluster_name = ric
		  ```
		  
  - Verify whether model deployment is successful. Use following commands to check that all pods are in Running state on **ric server** which gets created on AWS Ohio region with same name as ric2 service instance :

      ```sh  
      $ sudo kubectl get pods -n ricplt 
      NAME                                                        READY   STATUS    RESTARTS   AGE
      statefulset-ricplt-dbaas-server-0                           1/1     Running   0          4m27s
      deployment-ricplt-xapp-onboarder-f564f96dd-tn9kg            2/2     Running   0          4m26s
      deployment-ricplt-jaegeradapter-5444d6668b-4gkk7            1/1     Running   0          4m19s
      deployment-ricplt-vespamgr-54d75fc6d6-9ljs4                 1/1     Running   0          4m20s
      deployment-ricplt-alarmmanager-5f656dd7f8-knj9s             1/1     Running   0          4m17s
      deployment-ricplt-submgr-5499794897-8rj9v                   1/1     Running   0          4m21s
      deployment-ricplt-e2mgr-7984fcdcb5-mlfh6                    1/1     Running   0          4m24s
      deployment-ricplt-o1mediator-7b4c8547bc-82kb8               1/1     Running   0          4m18s
      deployment-ricplt-a1mediator-68f8677df4-cvck9               1/1     Running   0          4m22s
      r4-infrastructure-prometheus-server-dfd5c6cbb-wrpp2         1/1     Running   0          4m28s
      r4-infrastructure-kong-b7cdbc9dd-g9qlc                      2/2     Running   1          4m28s
      r4-infrastructure-prometheus-alertmanager-98b79ccf7-pvfql   2/2     Running   0          4m28s
      deployment-ricplt-appmgr-5b94d9f97-mr7ld                    1/1     Running   0          2m16s
      deployment-ricplt-rtmgr-768655fc98-q6x28                    1/1     Running   2          4m25s
      deployment-ricplt-e2term-alpha-6c85bcf675-n6ckf             1/1     Running   0          4m23s
      deployment-ricplt-rsm-7c47b9489-c7fwd                       1/1     Running   0          4m15s
      
      $ sudo kubectl get pods -n ricinfra
      ubuntu@ip-172-31-47-62:~$ sudo kubectl get pods -n ricinfra
      NAME                                         READY   STATUS      RESTARTS   AGE
      tiller-secret-generator-4r45b                0/1     Completed   0          4m36s
      deployment-tiller-ricxapp-797659c9bb-b4kdz   1/1     Running     0          4m36s  

#### ric2

  **Note :** *While deploying **ric2** model instance, an instance of its dependency **(cluster)** gets created automatically.*	  

  - Following required inputs need to be filled in
    
	- ric2 
	  ```sh
	  Instance Name = {name_of_instance}
	  k8scluster_name = ric
  	  ```	
	  - cluster
		```sh
		new_cluster = true
		
		# Note: use region_name "us-east-2" only, using other region_name require changes to rest of inputs parameter
		
		region_name = us-east-2
		```
	    - cluster-resource
	      ```sh
	      cluster_name = ric
		  ```	  

  - Verify whether model deployment is successful. Use following commands to check that all pods are in running state on **ric server** which gets created on AWS Ohio region with same name as ric2 service instance :

      ```sh  
      $ sudo kubectl get pods -n ricplt 
      NAME                                                        READY   STATUS    RESTARTS   AGE
      statefulset-ricplt-dbaas-server-0                           1/1     Running   0          4m27s
      deployment-ricplt-xapp-onboarder-f564f96dd-tn9kg            2/2     Running   0          4m26s
      deployment-ricplt-jaegeradapter-5444d6668b-4gkk7            1/1     Running   0          4m19s
      deployment-ricplt-vespamgr-54d75fc6d6-9ljs4                 1/1     Running   0          4m20s
      deployment-ricplt-alarmmanager-5f656dd7f8-knj9s             1/1     Running   0          4m17s
      deployment-ricplt-submgr-5499794897-8rj9v                   1/1     Running   0          4m21s
      deployment-ricplt-e2mgr-7984fcdcb5-mlfh6                    1/1     Running   0          4m24s
      deployment-ricplt-o1mediator-7b4c8547bc-82kb8               1/1     Running   0          4m18s
      deployment-ricplt-a1mediator-68f8677df4-cvck9               1/1     Running   0          4m22s
      r4-infrastructure-prometheus-server-dfd5c6cbb-wrpp2         1/1     Running   0          4m28s
      r4-infrastructure-kong-b7cdbc9dd-g9qlc                      2/2     Running   1          4m28s
      r4-infrastructure-prometheus-alertmanager-98b79ccf7-pvfql   2/2     Running   0          4m28s
      deployment-ricplt-appmgr-5b94d9f97-mr7ld                    1/1     Running   0          2m16s
      deployment-ricplt-rtmgr-768655fc98-q6x28                    1/1     Running   2          4m25s
      deployment-ricplt-e2term-alpha-6c85bcf675-n6ckf             1/1     Running   0          4m23s
      
      $ sudo kubectl get pods -n ricinfra
      ubuntu@ip-172-31-47-62:~$ sudo kubectl get pods -n ricinfra
      NAME                                         READY   STATUS      RESTARTS   AGE
      tiller-secret-generator-4r45b                0/1     Completed   0          4m36s
      deployment-tiller-ricxapp-797659c9bb-b4kdz   1/1     Running     0          4m36s  
      ```

  - To delete **ric2** model deployment go to **kiali-dashboard** and click on **TOSCA-deployement**  click on **instances**. select instance from instances list. after select instance it will show buttons then click on **delete** button.  


#### qp2, qp-driver2 and ts2

  **Note :** *While deploying **qp2, qp-driver2 and ts2** models instance, an instance of its dependency **(cluster)** gets created automatically.*

  - Following required inputs need to be filled in
  
    - qp2, qp-driver2 and ts2 :
	  ```sh
	  Instance Name = {name_of_instance}
  	  ```	 
	  - cluster
		```sh
				
		# Note: use region_name "us-east-2" only, using other region_name require changes to rest of inputs parameter
		
		region_name = us-east-2
		```
	    - cluster-resource
	      ```sh
	      cluster_name = ric
		  existing_cluster_ip = {PUBLIC_IP_OF_RIC_SERVER}
		  ```
  - Use following commands on **ric server** server to check that following pods are in running state :
  
    qp2:
	
      ```sh
      $ sudo kubectl get pods -n ricxapp
      NAME                                   READY   STATUS    RESTARTS   AGE
      1ricxapp-qp-dd9965f84-k2hkk             1/1     Running   0          10m
      ```
	qp-driver2:
      ```sh
      $ sudo kubectl get pods -n ricxapp
      NAME                                   READY   STATUS    RESTARTS   AGE
      ricxapp-qpdriver-67bbd4d8-p9bbh        1/1     Running   0          12m
      ```
	ts2:
      ```sh
      $ sudo kubectl get pods -n ricxapp
      NAME                                   READY   STATUS    RESTARTS   AGE
      ricxapp-trafficxapp-77449f7dbc-gknb8   1/1     Running   0          14m
      ```
	
  - REST API to undeploy **qp2, qp-driver2, ts2** instance 
  
    - Make sure following contain in header 

	    ```sh
      Content-Type:application/json
      ```

      ```sh
      DELETE https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/so/v1/instances/deleteInstance/{INSTANCE_NAME}
 
      e.g:

      DELETE https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/so/v1/instances/deleteInstance/qp2
      ```

  - After that click on **Instances** tab to see deployed instance with its names. Click on instance to see details like instance deployment status, output data, etc.

## Clean Environment

   - To Destroy **cci-gin** server, SSH into **GIN-BOOTSTRAP-0** server and run following commands :
  
     ```sh
     $ cd /opt/app/gin-deployments/gin-ansible
     $ ansible-playbook uninstall_gin-tf.yml -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars  "aws_instance_name={NAME_OF_AWS_INSTANCE} domain_name={DOMAIN_NAME}" --vault-password-file=vault-pwd.txt
     ```

   - *To destroy **GIN-BOOTSTRAP-0**, terminate it through AWS console.*

## Troubleshooting

Following are some sample APIs that can be used from a tool such as POSTMAN to troubleshoot GIN.

**IMPORTANT NOTE 1** : *REST requests to create service instances of models must include following header.*

  ```sh
  Content-Type:application/json
  ```
	
- To get all models from database :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models
  ```

- To get all models from database with metadata :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models/metadata
  ```

- To get specific TOSCA model data :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models/{name}
  ```

- To get nodeTemplates from DB based on substitute directive :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models/substitute/{nodeTypeName}
  ```

- To get nodeTemplates from DB based on a select directive :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models/select/{nodeTypeName}
  ```

- To get nodeTemplates from model :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models/{name}/nodetemplates
  ```

- To get substitution nodes from model :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models/{name}/abstract
  ```

- To find dangling requirements of a given model :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/db/models/{name}/dangling_requirements
  ```
  
- To get all instances from database :
  
  ```sh
  GET https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/so/v1/instances
  ```

- To delete a model from database :

  ```sh
  DELETE https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/compiler/v1/model/db/{MODEL_NAME}
  {
    "namespace": "{MODEL_SERVICE_URL}",
    "version": "tosca_simple_yaml_1_3",
    "includeTypes": true
  }
  ```

- To execute workflow steps of a model which has already been saved in the database :

  ```sh
  POST https://{NAME_OF_AWS_INSTANCE}-apisix-gateway.{DOMAIN_NAME}/so/v1/instances/{INSTANCE_NAME}/workflows/deploy
  {
    "list-steps-only": false,
    "execute-policy": true
  }
  ```
