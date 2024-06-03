# inesdata-ia-services



## Installation steps

### Intall Cert Manager:
kubectl apply -k common/cert-manager/cert-manager/base
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl apply -k common/cert-manager/kubeflow-issuer/

### Install Istio:
kubectl apply -k common/istio/istio-crds/base
kubectl apply -k common/istio/istio-namespace/base
kubectl apply -k common/istio/istio-install/base

### Install AuthService:
kubectl apply -k common/oidc-client/oidc-authservice/base

### Install Knative:
kubectl apply -k common/knative/knative-serving/overlays/gateways
kubectl apply -k common/istio/cluster-local-gateway/base

### Install Kubeflow Namespace:
kubectl apply -k common/kubeflow-namespace/base

### Install Kubeflow Roles:
kubectl apply -k common/kubeflow-roles/base

### Install Istio Resources:
kubectl apply -k common/istio/kubeflow-istio-resources/base

### Install Kubeflow Pipelines:
kubectl apply -k apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user

### Install Kserve:
kubectl apply -k contrib/kserve/kserve
kubectl apply -k contrib/kserve/models-web-app/overlays/kubeflow

### Install Central Dashboard:
kubectl apply -k apps/centraldashboard/upstream/overlays/kserve

### Install Admission Webhook:
kubectl apply -k apps/admission-webhook/upstream/overlays/cert-manager

### Install Notebooks:
kubectl apply -k apps/jupyter/notebook-controller/upstream/overlays/kubeflow
kubectl apply -k apps/jupyter/jupyter-web-app/upstream/overlays/istio

### Install PVC Viewer Controller
kubectl apply -k apps/pvcviewer-controller/upstream/default

### Install Profiles + KFAM
kubectl apply -k apps/profiles/upstream/overlays/kubeflow

### Install Volumes Web App
kubectl apply -k apps/volumes-web-app/upstream/overlays/istio

### Install User Namespace
kubectl apply -k common/user-namespace/base

### Install Keycloak
kubectl apply -k common/keycloak/overlays/istio 

### Check pods by namespace:
kubectl get pods -n cert-manager
kubectl get pods -n istio-system
kubectl get pods -n auth
kubectl get pods -n knative-serving
kubectl get pods -n kubeflow
kubectl get pods -n kubeflow-user-example-com

# KUBEFLOW ADMIN script user guide:
From kubeflow folder run ./kubeflow-admin.sh
```sh
./kubeflow-admin.sh
```
You will see the main menu:
```sh
KUBEFLOW ADMIN:
1) Create user
2) Delete user
3) List users
4) View user resources
5) Modify user resources
6) Exit
Type an option: 
```

## Create user
You must complete the kubeflow/common/user-namespace/base/params.env with the corresponding information.
Then run kubeflow-admin.sh and type the '1' opcion.
The script will remember that the user must be created on Keycloak before this step.
After that, a confirmation screen will be shown with the profile data and you will have to confirm it. The user will be created on kubeflow.

## Delete user
Run kubeflow-admin.sh and type the '2' opcion.
Type the profile name of the user to delete.
A confirmation screen will be shown and you will have to confirm it. The user will be removed from kubeflow.
Then you will have to remove the user on Keycloak.

## List users
Run kubeflow-admin.sh and type the '3' opcion.
The script will show a list with registered user on kubeflow.

## View user resources
Run kubeflow-admin.sh and type the '4' opcion.
Type the profile name of the user to see.
The script will display a list of resources available to the requested user in kubeflow.

## Modify user resources
Run kubeflow-admin.sh and type the '5' opcion.
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