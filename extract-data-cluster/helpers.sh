#!/bin/bash

# Helper to programming
# Log levels
# DEBUG: Detailed information, typically of interest only when diagnosing problems.
# INFO: Confirmation that things are working as expected.
# WARNING: An indication that something unexpected happened, or indicative of some problem in the near future (e.g. ‘disk space low’). The software is still working as expected.
# ERROR: Due to a more serious problem, the software has not been able to perform some function.
# CRITICAL: A serious error, indicating that the program itself may be unable to continue running.
# ALERT: A serious error, indicating that the program itself may be unable to continue running.
# EMERGENCY: A serious error, indicating that the program itself may be unable to continue running.
# $1 - log level
# $2 - type
# $3 - message
# $4 - resource
_logger(){

    # if loglevel is not defined, set to INFO   
    # Check if the function was called with the right number of arguments
    local _level="${1^^:-INFO}"
    local _type="${2:-No type}"
    local _message="${3:-No message}"
    local _rs="${4:-No resource}"

    _log_message="$(date): loglevel=\"${_level^^}\"  type=\"${_type}\" message=\"${_message}\" resource=\"${_rs}\""

    # Print the log message
    if [[ $_level =~ DEBUG|INFO|WARNING ]] && [ $logLevel == "DEBUG" ]; then
        echo "${_log_message}"
    fi

    if [ "$_level" == "INFO" ] && [ "${logLevel}" == "INFO" ]; then
        echo "${_log_message}"
    fi
}