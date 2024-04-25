#!/bin/bash

# Helper to programming
_logger(){

    # Check if the function was called with the right number of arguments
    local _level="${1:-INFO}"
    local _type="${2:-No type}"
    local _message="${3:-No message}"
    local _rs="${4:-No resource}"
    
    # Print the message
    echo "$(date): loglevel=\"${_level^^}\"  type=\"${_type}\" message=\"${_message}\" resource=\"${_rs}\""
}