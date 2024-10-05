#!/bin/bash

set +xe

#TODO base folder if not exists
export logLevel="DEBUG"
cwd=$(readlink -f "$(dirname "${0}")")
_date=$(date +%Y.%m.%d)
base_data_folder="${cwd}/extract-${_date}"
# Deafult kubeconfig
kubeconfig="${HOME}/.kube/config"

# Set the Base kubectl command
_kubectl="kubectl --kubeconfig ${kubeconfig}"

#shellcheck source=/dev/null
source helpers.sh

# Get all namespaced resources
# Return all namespaced resources
get_namespaced_resources(){

    _namespaced_bool="${1}"

    # Use kubectl to get all namespaced resources and with no headers,
    # print name of the resource and short the output
    namespaced_resources=("$(${_kubectl} api-resources --namespaced="${_namespaced_bool}" --no-headers=true -o name --sort-by=name )")
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

    local _namespace="${1:-default}"
    local _resource="${2}"
    local _object="${3}"

    if ${_namespaced_bool}; then
        local _end_data_folder="${base_data_folder}/${_namespace}/${_resource}"
    else
        local _end_data_folder="${base_data_folder}/cluster/${_resource}"
    fi

    # Create a folder for each namespace and resource
    mkdir -p "${_end_data_folder}"

    for ob in $_object; do

        ${_kubectl} get "${_resource}" -n "${_namespace}" "${ob}" -o yaml > "${_end_data_folder}/${ob}.yaml"
        _logger "DEBUG" "extract_resource,namespace=${_namespace}" "${ob}" "${_resource}"

    done
}

# Get all objects from a specific namespace and resource
# $1 - namespace
# $2 - resource
# Return all objects
get_objects(){

    local _namespace="${1:-default}"
    local _resource="${2}"
    local _objects=""

    # Use kubectl to get all objects from a specific namespace and resource
    _objects=$(${_kubectl} get "${_resource}" -n "${_namespace}" -ojsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "${_objects}" ]; then
        # extract_resource "$_namespace" "$_resource" "${_objects}"
        _logger "INFO" "get_object_function" "${_objects}" "${_resource}"
        extract_resource "$_namespace" "$_resource" "${_objects}"
    else
        _logger "DEBUG" "get_objects_function_else" "No objects found" "${_resource}"

    fi
}

main_for() {

    # Loop through the namespaces and resources
    if ${_namespaced_bool}; then

        _logger "DEBUG" "namespaces" "Getting objects from all namespaces"

        for ns in ${namespaces}; do

            _logger "DEBUG" "namespace" "${ns}"
            # Get all objects from a specific namespace and resource
            for rs in ${namespaced_resources}; do
                get_objects "${ns}" "${rs}"
            done

        done
    else
        # Loop through the resources
        # Get all objects from a specific resource
        for rs in ${namespaced_resources}; do
            get_objects "" "${rs}"
        done
    fi
}

# Execute the main function
# Check the value of the namespaced variable
# Call the main function
execute_main(){

    case "$check_bool" in

                true)
                    get_namespaces
                    get_namespaced_resources "true"
                    main_for
                    ;;
                false)
                    get_namespaced_resources "false"
                    main_for
                    ;;
                all)
                    get_namespaces
                    get_namespaced_resources "true"
                    main_for
                    get_namespaced_resources "false"
                    main_for
                    ;;
                *)
                    echo "Invalid value for --namespaced. Use true, false, or all."
                    exit 1
                    ;;
    esac

}


# Run the script
# $@ - arguments
# Entry point of the script
run(){

    local check_bool="unknown"
    _logger "INFO" "run" "Starting script"

    _logger "DEBUG" "run" "setting getops"
    getops=$(getopt -o n:k: --long namespaced:,kubeconfig: -n 'get.api.resources.sh' -- "$@")

    if [ $? != 0 ]; then
        echo "Failed parsing options." >&2
        exit 1
    fi

    eval set -- "$getops"

    while true; do

        case "$1" in
            -n|--namespaced)
                case "$2" in
                    true|false|all)
                        check_bool="$2"
                        shift 2
                        ;;
                    *)
                        echo "Invalid value for --namespaced. Use true, false, or all."
                        exit 1
                        ;;
                esac
                ;;
            -k|--kubeconfig)
                kubeconfig="$2"
                _kubectl="kubectl --kubeconfig ${kubeconfig}"
                _logger "DEBUG" "kubeconfig" "Using kubeconfig: ${kubeconfig}"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Invalid option: $1"
                exit 1
                ;;
        esac
    done

    execute_main
}

run "$@"



