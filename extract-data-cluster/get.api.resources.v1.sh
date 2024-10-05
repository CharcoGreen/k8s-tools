#!/bin/bash

# set -xe pipefail

cwd=$(readlink -f "$(dirname "${0}")")
data=$(date +%Y.%m.%d)
base_data_folder="${cwd}/extract-${data}"
kubeconfig="${HOME}/.kube/config"

# Set the Base kubectl command
_kubectl="kubectl --kubeconfig ${kubeconfig}"

#shellcheck source=/dev/null
source helpers.sh

# Get all namespaced resources
# Return all namespaced resources
get_namespaced_resources(){

    # Use kubectl to get all namespaced resources and with no headers, 
    # print name of the resource and short the output
    namespaced_resources=("$(${_kubectl} api-resources --namespaced=true --no-headers=true | awk '{print $1}' | sort | uniq)")
}

# Get all namespaces
# Return all namespaces
get_namespaces(){
    
    # Use kubectl to get all namespaces and with no headers,
    namespaces=$(${_kubectl} get namespaces -ojsonpath='{.items[*].metadata.name}')
}

# Extract all objects from a specific namespace and resource
# $1 - namespace
# $2 - resource
# $3 - objects
extract_resource(){

    local _namespace="${1}"
    local _resource="${2}"
    local _object="${3}"

    # Create a folder for each namespace and resource
    mkdir -p "${base_data_folder}/${_namespace}/${_resource}"
    
    for ob in $_object; do
        _logger "debug" "extract_resource" "${ob}" "${_resource}"
        ${_kubectl} get "${_resource}" -n "${_namespace}" "${ob}" -o yaml > "${base_data_folder}/${_namespace}/${_resource}/${ob}.yaml"
    done
}

# Get all objects from a specific namespace and resource
# $1 - namespace
# $2 - resource
# Return all objects
get_objects(){

    local _namespace="${1}"
    local _resource="${2}"
    local _objects=""

    # Use kubectl to get all objects from a specific namespace and resource
    _objects=$(${_kubectl} get "${_resource}" -n "${_namespace}" -ojsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "${_objects}" ]; then
        _logger "info" "get_object_function" "${_objects}" "${_resource}"
        extract_resource "$_namespace" "$_resource" "${_objects}"
    else
        _logger "debug" "get_objects_function_else" "No objects found" "${_resource}"
    fi
}

# Main function
# Call the functions

get_namespaced_resources
get_namespaces
get_objects "${namespaces}" "${namespaced_resources[@]}"

for ns in ${namespaces}; do

    _logger "debug" "namespace" "${ns}"
    for rs in ${namespaced_resources}; do
        
        get_objects "${ns}" "${rs}"
    done

done


