#!/bin/bash

# Function to create a profile
create_profile() {
  clear
  env_file="common/user-namespace/base/params.env"
  POD_NAME=$(kubectl get pods -n auth | grep keycloak | awk '{print $1}')
  
  # get profile name to include in kubernetes
  profile_name=$(grep '^profile-name=' "$env_file" | cut -d'=' -f2 | xargs)
  kc_pass=$(grep '^kc-pass=' "$env_file" | cut -d'=' -f2 | xargs)
  owner=$(grep '^user=' "$env_file" | cut -d'=' -f2 | xargs)
  cpu=$(grep '^cpu=' "$env_file" | cut -d'=' -f2 | xargs)
  memory=$(grep '^memory=' "$env_file" | cut -d'=' -f2 | xargs)
  #gpu_s=$(grep '^mig-gpu-5g=' "$env_file" | cut -d'=' -f2 | xargs)
  gpu_l=$(grep '^mig-gpu-20g=' "$env_file" | cut -d'=' -f2 | xargs)
  gpu_xl=$(grep '^gpu=' "$env_file" | cut -d'=' -f2 | xargs)
  storage=$(grep '^storage=' "$env_file" | cut -d'=' -f2 | xargs)

  echo "*** USER DATA ***"
  echo "Profile name: '$profile_name'"
  echo "Owner: '$owner'"
  echo "CPU: '$cpu'"
  echo "Memory: '$memory'"
#  echo "GPU S - mig-1g.5GB: '$gpu_s'"
  echo "GPU L - mig-3g.20GB: '$gpu_l'"
  echo "GPU XL - 40 GB: '$gpu_xl'"
  echo "Storage: '$storage'"

  read -p "Confirm? [y/N]: " confirm
  if [[ $confirm == [yY] ]]; then
    echo "*** CREATING USER ***"

    echo "You need to type the keycloak credentials to make this action."
    read -p "Type the keycloack admin user: " kc_adm_user
    read -sp "Type the keycloak admin pass: " kc_adm_pass
    # login
    kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user '$kc_adm_user' --password '$kc_adm_pass' --config /opt/keycloak/bin/kcadm.config'
    kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh create users -r kubeflow -s username='$profile_name' -s enabled=true --config /opt/keycloak/bin/kcadm.config ; /opt/keycloak/bin/kcadm.sh set-password -r kubeflow --username '$profile_name' --new-password '$kc_pass' -t --config /opt/keycloak/bin/kcadm.config'

    kubectl apply -k common/user-namespace/base
    kubectl wait --timeout=300s -n $profile_name --all --for=condition=Ready pod

    # Set the environment variables
    export PROFILE_NAME=$profile_name
    export CPU=$cpu
    export MEMORY=$memory

    # applying pod-default
    envsubst < ./common/user-namespace/base/pod-default.yaml | kubectl apply -f -
    # applying limit-range
    envsubst < ./common/user-namespace/base/limit-range.yaml | kubectl apply -f -
    # We apply the command again because otherwise the notebooks will not run up.
    sleep 3
    envsubst < ./common/user-namespace/base/limit-range.yaml | kubectl apply -f -

    profiles=$(kubectl get profiles -o jsonpath='{.items[*].metadata.name}')
    
    # Count the number of profiles
    profile_count=$(echo $profiles | wc -w)

    flag=0
    for profile in $profiles; do
      if [[ $profile == $profile_name ]]; then
        echo "Profile '$profile_name' created successfully."
        flag=1
        break
      fi
    done
    if [[ $flag == 0 ]]; then
      echo "Error creating '$profile_name' profile."
    fi
  else
    echo "Operation cancelled."
  fi

  read -n1 -s -r -p "Press any key to continue"
}

# Function to update param
update_param() {
    param=$1
    new_value=$2
    sed -i "s/^\($param *= *\).*/\1$new_value/" "$PARAMS_FILE"
}

# Function to import a list of user profiles
import_profile_list(){
  echo "NOTE: You need to create the 'common/user-namespace/base/import_users.csv' file with the user list with the following format before the import process:"
  echo "user,profile-name,pass,cpu,memory,gpu,mig-gpu-20g,storage"
  echo "user@company.com,user,password,8,16Gi,0,0,100Gi"

  read -n1 -s -r -p "Press any key to continue"
  # CSV file with users and their resources
  USER_FILE="common/user-namespace/base/import_users.csv"
  PARAMS_FILE="common/user-namespace/base/params.env"
  POD_NAME=$(kubectl get pods -n auth | grep keycloak | awk '{print $1}')
  echo
  echo "You need to type the keycloak credentials to import users."
  read -p "Type the keycloack admin user: " kc_adm_user
  read -sp "Type the keycloak admin pass: " kc_adm_pass
  # login
  kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user '$kc_adm_user' --password '$kc_adm_pass' --config /opt/keycloak/bin/kcadm.config'

  read -p "Confirm to import '$USER_FILE'? [y/N]: " confirm
  echo "*** CREATING USERS ***"
  if [[ $confirm == [yY] ]]; then
    # Read the file line by line
    tail -n +2 $USER_FILE | while IFS=, read -r user profile_name kc_pass cpu memory gpu mig_gpu_20g storage
    do

      kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh create users -r kubeflow -s username='$profile_name' -s enabled=true --config /opt/keycloak/bin/kcadm.config ; /opt/keycloak/bin/kcadm.sh set-password -r kubeflow --username '$profile_name' --new-password '$kc_pass' -t --config /opt/keycloak/bin/kcadm.config'

      # update params
      update_param "user" "$user"
      update_param "profile-name" "$profile_name"
      update_param "cpu" "$cpu"
      update_param "memory" "$memory"
      update_param "gpu" "$gpu"
      update_param "mig-gpu-20g" "$mig_gpu_20g"
      #update_param "mig-gpu-5g" "$mig_gpu_5g"
      update_param "storage" "$storage"
      update_param "kc-pass" "$kc_pass"

      kubectl apply -k common/user-namespace/base
      kubectl wait --timeout=300s -n $profile_name --all --for=condition=Ready pod

      # Set the environment variables
      export PROFILE_NAME=$profile_name
      export CPU=$cpu
      export MEMORY=$memory

      # applying pod-default
      envsubst < ./common/user-namespace/base/pod-default.yaml | kubectl apply -f -
      # applying limit-range
      envsubst < ./common/user-namespace/base/limit-range.yaml | kubectl apply -f -
      # We apply the command again because otherwise the notebooks will not run up.
      sleep 3
      envsubst < ./common/user-namespace/base/limit-range.yaml | kubectl apply -f -
        
      profiles=$(kubectl get profiles -o jsonpath='{.items[*].metadata.name}')
      
      # Count the number of profiles
      profile_count=$(echo $profiles | wc -w)

      flag=0
      for profile in $profiles; do
        if [[ $profile == $profile_name ]]; then
          echo "Profile '$profile_name' created successfully."
          flag=1
          break
        fi
      done
      if [[ $flag == 0 ]]; then
        echo "Error creating '$profile_name' profile."
      fi
    done
  else
    echo "Operation cancelled."
  fi

  # restore params file
  update_param "user" "admin@gmv.com"
  update_param "profile-name" "admin"
  update_param "cpu" "2"
  update_param "memory" "4Gi"
  update_param "gpu" "0"
  update_param "mig-gpu-20g" "0"
  #update_param "mig-gpu-5g" "0"
  update_param "storage" "50Gi"
  update_param "kc-pass" "-"

  read -n1 -s -r -p "Press any key to continue"
}

# Function to delete a profile
delete_profile() {
  read -p "Enter the profile name to delete: " profile_name

  POD_NAME=$(kubectl get pods -n auth | grep keycloak | awk '{print $1}')
  read -p "Confirm to delete '$profile_name'? [y/N]: " confirm
  if [[ $confirm == [yY] ]]; then
    echo "You need to type the keycloak credentials to make this action."
    read -p "Type the keycloack admin user: " kc_adm_user
    read -sp "Type the keycloak admin pass: " kc_adm_pass
    kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user '$kc_adm_user' --password '$kc_adm_pass' --config /opt/keycloak/bin/kcadm.config'
    echo "*** DELETING USER ***"
    kubectl delete profile $profile_name

    # login
    kc_user_id=$(kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh get users -r kubeflow -q username='$profile_name' --fields id --config /opt/keycloak/bin/kcadm.config' | grep -o '"id" : "[^"]*' | grep -o '[^"]*$')
    kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh delete users/'$kc_user_id' -r kubeflow --config /opt/keycloak/bin/kcadm.config'

    # Verification
    for i in {1..15}; do
      sleep 1
      profiles=$(kubectl get profiles -o jsonpath='{.items[*].metadata.name}')
    
      # Count the number of profiles
      profile_count=$(echo $profiles | wc -w)

      flag=0
      for profile in $profiles; do
        if [[ $profile == $profile_name ]]; then
          flag=1
          break
        fi
      done
      if [[ $flag == 1 ]]; then
        echo "Error deleting '$profile_name' profile."
      else
        echo "Profile '$profile_name' not found or deleted successfully."
      fi
      
      read -n1 -s -r -p "Press any key to continue"
      return
    done

    echo "Error: Could not verify the deletion of the profile '$profile_name' within the expected time. Please check manually."
  else
    echo "Operation cancelled."
  fi

  read -n1 -s -r -p "Press any key to continue"
}

delete_user_list(){
  echo "NOTE: You need to create the 'common/user-namespace/base/delte_users.csv' file with the user list with the following format before the delete process:"
  echo "profile-name"
  echo "user"

  read -n1 -s -r -p "Press any key to continue"

  # CSV file with users and their resources
  USER_FILE="common/user-namespace/base/delete_users.csv"
  POD_NAME=$(kubectl get pods -n auth | grep keycloak | awk '{print $1}')
  echo "You need to type the keycloak credentials to delete users."
  read -p "Type the keycloack admin user: " kc_adm_user
  read -sp "Type the keycloak admin pass: " kc_adm_pass
  # login
  kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user '$kc_adm_user' --password '$kc_adm_pass' --config /opt/keycloak/bin/kcadm.config'

  read -p "Confirm to delete '$USER_FILE'? [y/N]: " confirm
  echo
  echo "*** DELETING USERS ***"
  if [[ $confirm == [yY] ]]; then
    # Read the file line by line
    tail -n +2 $USER_FILE | while IFS=, read -r profile_name
    do
      # Delete the profile from the cluster
      kubectl delete profile $profile_name
      kc_user_id=$(kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh get users -r kubeflow -q username='$profile_name' --fields id --config /opt/keycloak/bin/kcadm.config' | grep -o '"id" : "[^"]*' | grep -o '[^"]*$')
      kubectl exec -n auth $POD_NAME -- bash -c '/opt/keycloak/bin/kcadm.sh delete users/'$kc_user_id' -r kubeflow --config /opt/keycloak/bin/kcadm.config'

      # Verification
      for i in {1..15}; do
        sleep 1
        profiles=$(kubectl get profiles -o jsonpath='{.items[*].metadata.name}')
      
        # Count the number of profiles
        profile_count=$(echo $profiles | wc -w)

        flag=0
        for profile in $profiles; do
          if [[ $profile == $profile_name ]]; then
            flag=1
            break
          fi
        done
        if [[ $flag == 1 ]]; then
          echo "Error deleting '$profile_name' profile."
        else
          echo "Profile '$profile_name' not found or deleted successfully."
        fi
        break
      done
    done
  else
    echo "Operation cancelled."
  fi

  read -n1 -s -r -p "Press any key to continue"
}

# Function to list all profiles and count them
list_users() {
  # List all profiles
  profiles=$(kubectl get profiles -o jsonpath='{.items[*].metadata.name}')
  
  # Count the number of profiles
  profile_count=$(echo $profiles | wc -w)

  echo "Profiles in the cluster:"
  for profile in $profiles; do
    echo "- $profile"
  done
  
  echo "Total number of profiles: $profile_count"

  read -n1 -s -r -p "Press any key to continue"
}

# Function to view the resources of a profile
view_profile_resources() {
  read -p "Enter the profile name: " profile_name

  resources=$(kubectl get profile $profile_name -o json)

  echo "Resources available for profile '$profile_name':"
  echo "$resources"

  read -n1 -s -r -p "Press any key to continue"
}

# Function to modify the CPU resources of a profile
modify_cpu_resources() {
  clear
  echo "KUBEFLOW ADMIN:"
  PS3='Type the CPU value to modify: '
  options=("S - 2 CPU" "M - 4 CPU" "L - 8 CPU" "XL - 16 CPU" "Other" "Cancel")
  select opt in "${options[@]}"
  do
    case $opt in
      "S - 2 CPU")
        new_value='2'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/cpu\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.cpu}')
        if [ "$current_value" == "$new_value" ]; then
          echo "CPU updated to '$new_value'"
        else
          echo "Error updating CPU"
        fi
        ;;
      "M - 4 CPU")
        new_value='4'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/cpu\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.cpu}')
        if [ "$current_value" == "$new_value" ]; then
          echo "CPU updated to '$new_value'"
        else
          echo "Error updating CPU"
        fi
        ;;
      "L - 8 CPU")
        new_value='8'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/cpu\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.cpu}')
        if [ "$current_value" == "$new_value" ]; then
          echo "CPU updated to '$new_value'"
        else
          echo "Error updating CPU"
        fi
        ;;
      "XL - 16 CPU")
        new_value='16'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/cpu\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.cpu}')
        if [ "$current_value" == "$new_value" ]; then
          echo "CPU updated to '$new_value'"
        else
          echo "Error updating CPU"
        fi
        ;;
      "Other")
        read -p "Enter the new CPU value (e.g. 10): " new_value
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/cpu\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.cpu}')
        if [ "$current_value" == "$new_value" ]; then
          echo "CPU updated to '$new_value'"
        else
          echo "Error updating CPU"
        fi
        ;;
      "Cancel")
        show_menu
        ;;
      *) 
        echo "Invalid option $REPLY"
        ;;
    esac
  done
}

# Function to modify the Memory resources of a profile
modify_memory_resources() {
  clear
  echo "KUBEFLOW ADMIN:"
  PS3='Type the Memory value to modify: '
  options=("S - 4 Gi" "M - 8 Gi" "L - 16 Gi" "XL - 32 Gi" "Other" "Cancel")
  select opt in "${options[@]}"
  do
    case $opt in
      "S - 4 Gi")
        new_value='4Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/memory\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.memory}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Memory updated to '$new_value'"
        else
          echo "Error updating Memory"
        fi
        ;;
      "M - 8 Gi")
        new_value='8Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/memory\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.memory}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Memory updated to '$new_value'"
        else
          echo "Error updating Memory"
        fi
        ;;
      "L - 16 Gi")
        new_value='16Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/memory\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.memory}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Memory updated to '$new_value'"
        else
          echo "Error updating Memory"
        fi
        ;;
      "XL - 32 Gi")
        new_value='32Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/memory\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.memory}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Memory updated to '$new_value'"
        else
          echo "Error updating Memory"
        fi
        ;;
      "Other")
        read -p "Enter the new Memory value (e.g. 16Gi): " new_value
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/memory\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.memory}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Memory updated to '$new_value'"
        else
          echo "Error updating Memory"
        fi
        ;;
        "Cancel")
        show_menu
        ;;
      *)
        echo "Invalid option $REPLY"
        ;;
    esac
  done
}

# Function to modify the GPU resources of a profile
modify_gpu_resources() {
  clear
  echo "KUBEFLOW ADMIN:"
  PS3='Type the GPU value to modify: '
  options=("S - mig-1g.5GB (Not supported yet)" "L - mig-3g.20GB" "XL - 40 GB" "Cancel")
  select opt in "${options[@]}"
  do
    case $opt in
      "S - mig-1g.5GB (Not supported yet)")
        echo "mig-1g.5GB not supported yet"
        #read -p "Enter the new mig-1g.5GB value (e.g. 2): " new_value
        #kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.nvidia.com~1mig-1g.5gb\", \"value\": \"$new_value\"}]"

        #current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.nvidia\.com\/mig-1g\.5gb}')
        #if [ "$current_value" == "$new_value" ]; then
        #  echo "mig-1g.5GB updated to '$new_value'"
        #else
        #  echo "Error updating mig-1g.5GB"
        #fi
        ;;
      "L - mig-3g.20GB")
        read -p "Enter the new mig-3g.20GB value (e.g. 2): " new_value
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.nvidia.com~1mig-3g.20gb\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.nvidia\.com\/mig-3g\.20gb}')
        if [ "$current_value" == "$new_value" ]; then
          echo "mig-3g.20GB updated to '$new_value'"
        else
          echo "Error updating mig-3g.20GB"
        fi
        ;;
      "XL - 40 GB")
        read -p "Enter the new GPU value (e.g. 2): " new_value
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.nvidia.com~1gpu\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.nvidia\.com\/gpu}')
        if [ "$current_value" == "$new_value" ]; then
          echo "GPU updated to '$new_value'"
        else
          echo "Error updating GPU"
        fi
        ;;
      "Cancel")
        show_menu
        ;;
      *)
        echo "Invalid option $REPLY"
        ;;
    esac
  done
}

# Function to modify the Storage resources of a profile
modify_storage_resources() {
  clear
  echo "KUBEFLOW ADMIN:"
  PS3='Type the Storage value to modify: '
  options=("S - 50 Gi" "M - 100 Gi" "L - 150 Gi" "XL - 200 Gi" "Other" "Cancel")
  select opt in "${options[@]}"
  do
    case $opt in
      "S - 50 Gi")
        new_value='50Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.storage\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.storage}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Storage updated to '$new_value'"
        else
          echo "Error updating Storage"
        fi
        ;;
      "M - 100 Gi")
        new_value='100Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.storage\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.storage}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Storage updated to '$new_value'"
        else
          echo "Error updating Storage"
        fi
        ;;
      "L - 150 Gi")
        new_value='150Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.storage\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.storage}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Storage updated to '$new_value'"
        else
          echo "Error updating Storage"
        fi
        ;;
      "XL - 200 Gi")
        new_value='200Gi'
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.storage\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.storage}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Storage updated to '$new_value'"
        else
          echo "Error updating Storage"
        fi
        ;;
      "Other")
        read -p "Enter the new Storage value (e.g. 100Gi): " new_value
        kubectl patch profile $profile_name --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/resourceQuotaSpec/hard/requests.storage\", \"value\": \"$new_value\"}]"

        current_value=$(kubectl get profile $profile_name -o jsonpath='{.spec.resourceQuotaSpec.hard.requests\.storage}')
        if [ "$current_value" == "$new_value" ]; then
          echo "Storage updated to '$new_value'"
        else
          echo "Error updating Storage"
        fi
        ;;
      "Cancel")
        show_menu
        ;;
      *)
        echo "Invalid option $REPLY"
        ;;
    esac
  done
}

# Function to modify the resources of a profile
modify_profile_resources() {
  clear
  echo "KUBEFLOW ADMIN:"
  read -p "Enter the profile name to modify: " profile_name
  if kubectl get profile $profile_name &>/dev/null; then
    PS3='Type the resource to modify on '$profile_name' profile: '
    options=("CPU" "Memory" "GPU" "Storage" "Cancel")
    select opt in "${options[@]}"
    do
      case $opt in
        "CPU")
          modify_cpu_resources
          ;;
        "Memory")
          modify_memory_resources
          ;;
        "GPU")
          modify_gpu_resources
          ;;
        "Storage")
          modify_storage_resources
          ;;
        "Cancel")
          show_menu
          ;;
        *) echo "Invalid option $REPLY";;
      esac
    done
  else
    echo "Profile '$profile_name' not found."
  fi
  read -n1 -s -r -p "Press any key to continue"
}

# Function to show the main menu
show_menu() {
  while true; do
    clear
    echo "KUBEFLOW ADMIN:"
    options=("Create user" "Import user list" "Delete user" "Delete user list" "List users" "View user resources" "Modify user resources" "Exit")
    PS3='Type an option: '
    select opt in "${options[@]}"
    do
      case $opt in
        "Create user")
          create_profile
          break
          ;;
        "Import user list")
          import_profile_list
          break
          ;;
        "Delete user")
          delete_profile
          break
          ;;
        "Delete user list")
          delete_user_list
          break
          ;;
        "List users")
          list_users
          break
          ;;
        "View user resources")
          view_profile_resources
          break
          ;;
        "Modify user resources")
          modify_profile_resources
          break
          ;;
        "Exit")
          clear
          exit 0
          ;;
        *)
          echo "Invalid option $REPLY"
          ;;
      esac
    done
  done
}

# Run the main menu
show_menu
