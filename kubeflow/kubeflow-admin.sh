#!/bin/bash

# Function to create a profile
create_profile() {
  echo "NOTE: User must be created on Keycloak before this."

  read -n1 -s -r -p "Press any key to continue"
  clear
  read -p "Enter the profile name (e.g. company-user): " profile_name
  read -p "Enter the profile owner (format user@company.com): " owner
  read -p "Enter the amount of CPU: " cpu
  read -p "Enter the amount of memory (e.g., 16Gi): " memory
#  read -p "Enter the amount of GPUs S - mig-1g.5GB: " gpu_s
  read -p "Enter the amount of GPUs L - mig-3g.20GB: " gpu_l
  read -p "Enter the amount of GPUs XL - 40 GB: " gpu_xl
  read -p "Enter the amount of storage (e.g., 100Gi): " storage

  echo "Profile name: '$profile_name'."
  echo "Owner: '$owner'."
  echo "CPU: '$cpu'."
  echo "Memory: '$memory'."
#  echo "GPU S - mig-1g.5GB: '$gpu_s'."
  echo "GPU L - mig-3g.20GB: '$gpu_l'."
  echo "GPU XL - 40 GB: '$gpu_xl'."
  echo "Storage: '$storage'."
  read -p "Confirm? [y/N]: " confirm
  if [[ $confirm == [yY] ]]; then
    cat <<EOF | kubectl apply -f -
apiVersion: kubeflow.org/v1beta1
kind: Profile
metadata:
  name: $profile_name
spec:
  owner:
    kind: User
    name: $owner
  resourceQuotaSpec:
    hard:
      cpu: "$cpu"
      memory: "$memory"
      requests.nvidia.com/gpu: "$gpu_xl"
      requests.nvidia.com/mig-3g.20gb: "$gpu_l"
      requests.storage: "$storage"
EOF
#      requests.nvidia.com/mig-1g.5gb: "$gpu_s" NOT SUPPORTED YET

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

# Function to delete a profile
delete_profile() {
  read -p "Enter the profile name to delete: " profile_name

  read -p "Are you sure you want to delete the profile '$profile_name'? [y/N]: " confirm
  if [[ $confirm == [yY] ]]; then
    kubectl delete profile $profile_name
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
        echo "NOTE: User must be deleted on Keycloak after this."
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
  options=("S - mig-1g.5GB" "L - mig-3g.20GB" "XL - 40 GB" "Cancel")
  select opt in "${options[@]}"
  do
    case $opt in
      "S - mig-1g.5GB")
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
    options=("Create user" "Delete user" "List users" "View user resources" "Modify user resources" "Exit")
    PS3='Type an option: '
    select opt in "${options[@]}"
    do
      case $opt in
        "Create user")
          create_profile
          break
          ;;
        "Delete user")
          delete_profile
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
