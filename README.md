# inesdata-ia-services



## Installation steps

### Intall Cert Manager:
```sh
kubectl apply -k common/cert-manager/cert-manager/base
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl apply -k common/cert-manager/kubeflow-issuer/
```

### Install Istio:
```sh
kubectl apply -k common/istio/istio-crds/base
kubectl apply -k common/istio/istio-namespace/base
kubectl apply -k common/istio/istio-install/base
```

### Install AuthService:
```sh
kubectl apply -k common/oidc-client/oidc-authservice/base
```

### Install Knative:
```sh
kubectl apply -k common/knative/knative-serving/overlays/gateways
kubectl apply -k common/istio/cluster-local-gateway/base
```

### Install Kubeflow Namespace:
```sh
kubectl apply -k common/kubeflow-namespace/base
```

### Install Kubeflow Roles:
```sh
kubectl apply -k common/kubeflow-roles/base
```

### Install Istio Resources:
```sh
kubectl apply -k common/istio/kubeflow-istio-resources/base
```

### Install Kubeflow Pipelines:
```sh
kubectl apply -k apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user
```

### Install Kserve:
```sh
kubectl apply -k contrib/kserve/kserve
kubectl apply -k contrib/kserve/models-web-app/overlays/kubeflow
```

### Install Central Dashboard:
```sh
kubectl apply -k apps/centraldashboard/upstream/overlays/kserve
```

### Install Admission Webhook:
```sh
kubectl apply -k apps/admission-webhook/upstream/overlays/cert-manager
```

### Install Notebooks:
```sh
kubectl apply -k apps/jupyter/notebook-controller/upstream/overlays/kubeflow
kubectl apply -k apps/jupyter/jupyter-web-app/upstream/overlays/istio
```

### Install PVC Viewer Controller
```sh
kubectl apply -k apps/pvcviewer-controller/upstream/default
```

### Install Profiles + KFAM
```sh
kubectl apply -k apps/profiles/upstream/overlays/kubeflow
```

### Install Volumes Web App
```sh
kubectl apply -k apps/volumes-web-app/upstream/overlays/istio
```

### Install User Namespace
```sh
kubectl apply -k common/user-namespace/base
```

### Install Keycloak
```sh
kubectl apply -k common/keycloak/overlays/istio 
```

### Check pods by namespace:
```sh
kubectl get pods -n cert-manager
kubectl get pods -n istio-system
kubectl get pods -n auth
kubectl get pods -n knative-serving
kubectl get pods -n kubeflow
kubectl get pods -n kubeflow-user-example-com
```

# KUBEFLOW ADMIN script user guide:
From kubeflow folder run the following command:
```sh
./kubeflow-admin.sh
```
You will see the main menu:
```sh
KUBEFLOW ADMIN:
1) Create user
2) Import user list
3) Delete user
4) Delete user list
5) List users
6) View user resources
7) Modify user resources
8) Exit
Type an option: 
```

## Create user
You must complete the kubeflow/common/user-namespace/base/params.env with the corresponding information.

Then run ``kubeflow-admin.sh`` and type the ``1`` opcion.

The script will remember that the user must be created on Keycloak before this step.

After that, a confirmation screen will be shown with the profile data and you will have to confirm it. The user will be created on kubeflow.

## Import user list
You need to create a ``common/user-namespace/base/import_users.csv`` with the following format befor start the process:
```
user,profile-name,cpu,memory,gpu,mig-gpu-20g,storage
user0@company.com,user0,8,16Gi,0,0,100Gi
user1@company.com,user1,4,32Gi,1,0,50Gi

```
Note: make a blank line at the end of file.

Then run ``kubeflow-admin.sh`` and type the ``2`` opcion.

A confirmation screen will be shown befor start the import. The users will be created on kubeflow.

After that the script will remember that the user must be created on Keycloak before this step.

## Delete user
Run ``kubeflow-admin.sh`` and type the ``3`` opcion.

Type the profile name of the user to delete.

A confirmation screen will be shown and you will have to confirm it. The user will be removed from kubeflow.

Then you will have to remove the user on Keycloak.

## Delete user list
Run ``kubeflow-admin.sh`` and type the ``4`` opcion.

You need to create a ``common/user-namespace/base/delete_users.csv`` with the following format befor start the process:
```
profile-name
user0
user1

```
Note: make a blank line at the end of file.

A confirmation screen will be shown and you will have to confirm it. The users will be removed from kubeflow.

Then you will have to remove the user on Keycloak.

## List users
Run ``kubeflow-admin.sh`` and type the ``5`` opcion.

The script will show a list with registered user on kubeflow.

## View user resources
Run ``kubeflow-admin.sh`` and type the ``6`` opcion.

Type the profile name of the user to see.

The script will display a list of resources available to the requested user in kubeflow.

## Modify user resources
Run ``kubeflow-admin.sh`` and type the ``7`` opcion.

Type the profile name of the user to modify.

You will see the following menu:
```sh
KUBEFLOW ADMIN:
Enter the profile name to modify: admin
1) CPU
2) Memory
3) GPU
4) Storage
5) Cancel
Type the resource to modify on admin profile: 
```
Then type the option to modify and select the value to be modified.