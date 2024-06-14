# Inesdata-IA-Services



## Pasos de instalación

### Intalar Cert Manager:
```sh
kubectl apply -k common/cert-manager/cert-manager/base
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl apply -k common/cert-manager/kubeflow-issuer/
```

### Intalar Istio:
```sh
kubectl apply -k common/istio/istio-crds/base
kubectl apply -k common/istio/istio-namespace/base
kubectl apply -k common/istio/istio-install/base
```

### Intalar AuthService:
```sh
kubectl apply -k common/oidc-client/oidc-authservice/base
```

### Intalar Knative:
```sh
kubectl apply -k common/knative/knative-serving/overlays/gateways
kubectl apply -k common/istio/cluster-local-gateway/base
```

### Intalar Kubeflow Namespace:
```sh
kubectl apply -k common/kubeflow-namespace/base
```

### Intalar Kubeflow Roles:
```sh
kubectl apply -k common/kubeflow-roles/base
```

### Intalar Istio Resources:
```sh
kubectl apply -k common/istio/kubeflow-istio-resources/base
```

### Intalar Kubeflow Pipelines:
```sh
kubectl apply -k apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user
```

### Intalar Kserve:
```sh
kubectl apply -k contrib/kserve/kserve
kubectl apply -k contrib/kserve/models-web-app/overlays/kubeflow
```

### Intalar Central Dashboard:
```sh
kubectl apply -k apps/centraldashboard/upstream/overlays/kserve
```

### Intalar Admission Webhook:
```sh
kubectl apply -k apps/admission-webhook/upstream/overlays/cert-manager
```

### Intalar Notebooks:
```sh
kubectl apply -k apps/jupyter/notebook-controller/upstream/overlays/kubeflow
kubectl apply -k apps/jupyter/jupyter-web-app/upstream/overlays/istio
```

### Intalar PVC Viewer Controller
```sh
kubectl apply -k apps/pvcviewer-controller/upstream/default
```

### Intalar Profiles + KFAM
```sh
kubectl apply -k apps/profiles/upstream/overlays/kubeflow
```

### Intalar Volumes Web App
```sh
kubectl apply -k apps/volumes-web-app/upstream/overlays/istio
```

### Intalar User Namespace
```sh
kubectl apply -k common/user-namespace/base
```

### Intalar Keycloak
```sh
kubectl apply -k common/keycloak/overlays/istio 
```

### Comprobar PODs por cada namespace:
```sh
kubectl get pods -n cert-manager
kubectl get pods -n istio-system
kubectl get pods -n auth
kubectl get pods -n knative-serving
kubectl get pods -n kubeflow
kubectl get pods -n kubeflow-user-example-com
```

# Guía de uso del script de administración de Kubeflow:
Desde la carpeta kubeflow, lanzar el siguiente comando:
```sh
./kubeflow-admin.sh
```
En pantalla se mostrará el menu principal:
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

## Crear usuario
Previamente debe existir el fichero ``kubeflow/common/user-namespace/base/params.env`` con la información correspondiente al perfil que se quiere crear.

Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``1``.

Seguidamente, aparecerá una pantalla de confirmación con los datos del perfile y solicitará confirmacion para proceder a crear el usuario en Kubeflow y Keycloak.

## Importar usuarios desde CSV
Es necesario crear ``common/user-namespace/base/import_users.csv`` con el siguiente formato antes de continuar con el proceso:
```sh
user,profile-name,kc-pass,cpu,memory,gpu,mig-gpu-20g,storage
user0@company.com,user0,pass0,8,16Gi,0,0,100Gi
user1@company.com,user1,pass1,4,32Gi,1,0,50Gi

```
NOTA: Dejar una linea en blanco al final del fichero
NOTA 2: kc-pass sera la contraseña de acceso a Kubeflow que se creara al darse de alta en Keycloak.

Seguidamente ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``2``.

Aparecerá una pantalla de confirmación antes de comenzar la importación.

## Eliminar usuario
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``3``.

Escribir por teclado el nombre del perfil que se desea elinminar.

Aparecerá una pantalla de confirmación. Tras verificar la acción se procedera a eliminar el usuario de Kubeflow y Keycloak.

## Eliminar una lista de usuarios
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``4``.

Es necesario crear ``common/user-namespace/base/delete_users.csv`` con el siguiente formato antes de continuar con el proceso:
```sh
profile-name
user0
user1

```
NOTA: Dejar una linea en blanco al final del fichero

Aparecerá una pantalla de confirmación. Tras verificar la acción se procedera a eliminar los usuarios de Kubeflow y Keycloak.

## Listar usuarios
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``5``.

El script mostrara una lista con los usuarios dados de alta en Kubeflow.

## Ver recursos de usuario
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``6``.

Escribir por teclado el nombre del perfil que se desea consultar.

El script mostrara una lista con los recursos disponibles para el usuario solicitado en Kubeflow.

## Modicar recursos de usuario
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``7``.

Escribir por teclado el nombre del perfil que se desea modificar.

En pantalla se mostrará el siguiente menú:
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
Seguidamente seleccionar la opcion del recurso a modificar y seleccionar el valor deseado para ser aplicado.

## Salir del administrador de Kubeflow
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``8``.