#!/bin/sh

DEMO_VAULT_PATHS=(dev sit uat perf prod)
DEMO_VAULT_KEYS=(owner created_on cost_center_id artifactory_bin_path)
DEMO_VAULT_VALUES=(Jeff 12-27-17 0112 https://artifactory.cigna.internal/myapp/artifact.rpm)
VAULT_ADDR=""
VAULT_TOKEN=""

prompt(){

  if [ "$#" -eq "0" ]; then
    echo "${@}"
    echo -n "Please enter the HTTP URL of your Vault cluster: "
    read vault_addr
    export VAULT_ADDR=$vault_addr

    echo -n "Please enter your Token for writing to Vault: "
    read vault_token
    export VAULT_TOKEN=$vault_token
  else
    export VAULT_ADDR=$1
    export VAULT_TOKEN=$2
  fi
}

generate_data(){

  local count=0
  for i in "${DEMO_VAULT_PATHS[@]}"
  do
    for j in "${DEMO_VAULT_KEYS[@]}"
    do
      vault write secret/${i}/${j} value=${DEMO_VAULT_VALUES[$count]}
      count=$(( $count + 1))
    done
    count=0
  done
}

interrogate_path(){

  local vault_path=""
  local vault_field=""

  if [ "$#" -eq "0" ]; then
    echo -n "Please enter a path to query for secrets: "
    read vault_path
  else
    vault_path=$1
  fi

  if [ "$#" -eq "2" ]; then
    vault_path=$1
    vault_field=$2
  fi

  # if item is a key, we read from vault
  if [[ ! "$vault_path" =~ /$ ]]; then
    vault read $vault_path/$vault_field
  else

    # list keys at current path
    local keys=( $(vault list $vault_path | tail -n +3) )

    # iterate through keys
    for i in "${keys[@]}"
    do
      # if item is another path, we recurse
      if [[ ${i} =~ /$ ]]; then
        interrogate_path $vault_path/${i}
      else
        echo "Reading ${vault_path}/${i}"
        vault read $vault_path/${i}
      fi
    done
  fi
}



prompt ${@}
generate_data
interrogate_path
