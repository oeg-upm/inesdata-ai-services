# **Uso del script de administración**

---

Desde la carpeta ``kubeflow``, lanzar el siguiente comando:
```
./kubeflow-admin.sh
```
En pantalla se mostrará el menú principal:
```
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

Seguidamente, aparecerá una pantalla de confirmación con los datos del perfil y solicitará confirmación para proceder a crear el usuario en `Kubeflow` y `Keycloak`.

## Importar usuarios desde CSV

Es necesario crear ``common/user-namespace/base/import_users.csv`` con el siguiente formato antes de continuar con el proceso:
```
user,profile-name,kc-pass,cpu,memory,gpu,mig-gpu-20g,storage
user0@company.com,user0,pass0,8,16Gi,0,0,100Gi
user1@company.com,user1,pass1,4,32Gi,1,0,50Gi

```
!!! warning

    Dejar una linea en blanco al final del fichero.

!!! note

    `kc-pass` será la contraseña de acceso a `Kubeflow` que se creará al darse de alta en `Keycloak`.

Seguidamente ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``2``.

Aparecerá una pantalla de confirmación antes de comenzar la importación.

## Eliminar usuario

Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``3``.

Escribir por teclado el nombre del perfil que se desea elinminar.

Aparecerá una pantalla de confirmación. Tras verificar la acción se procedera a eliminar el usuario de `Kubeflow` y `Keycloak`.

## Eliminar una lista de usuarios

Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``4``.

Es necesario crear ``common/user-namespace/base/delete_users.csv`` con el siguiente formato antes de continuar con el proceso:
```
profile-name
user0
user1

```
!!! warning

    Dejar una linea en blanco al final del fichero

Aparecerá una pantalla de confirmación. Tras verificar la acción se procederá a eliminar los usuarios de `Kubeflow` y `Keycloak`.

## Listar usuarios

Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``5``.

El script mostrará una lista con los usuarios dados de alta en `Kubeflow`.

## Ver recursos de usuario
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``6``.

Escribir por teclado el nombre del perfil que se desea consultar.

El script mostrará una lista con los recursos disponibles para el usuario solicitado en `Kubeflow`.

## Modicar recursos de usuario
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``7``.

Escribir por teclado el nombre del perfil que se desea modificar.

En pantalla se mostrará el siguiente menú:
```
KUBEFLOW ADMIN:
Enter the profile name to modify: admin
1) CPU
2) Memory
3) GPU
4) Storage
5) Cancel
Type the resource to modify on admin profile: 
```
Seguidamente seleccionar la opción del recurso a modificar y seleccionar el valor deseado para ser aplicado.

## Salir del administrador de Kubeflow
Ejecutar ``kubeflow-admin.sh`` y seleccionar la opción ``8``.
