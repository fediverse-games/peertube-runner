#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail            
             
echo 'Starting Peertube Runner docker container... container maintained by Fediverse.Games'
echo 'For any issues or assistance, check us out on GitHub:'
echo 'https://github.com/fediverse-games/peertube-runner-docker'    
           
echo 'Building peertube config...'

if [ -z "${PEERTUBE_RUNNER_NAME}" ]
then
    export PEERTUBE_RUNNER_NAME="${HOSTNAME}"
fi

if [ -f "${PEERTUBE_CONFIG}" ]
then
    echo "Mounted config file detected, copying to config directory."
    mv "${PEERTUBE_CONFIG}" "${PEERTUBE_CONFIG_DIR}/config.toml"
else
    echo "Creating config file from env..."
    if [ -z "${PEERTUBE_URL}" ]
    then
        echo 'ERROR: Peertube URL required to run container. Terminating...'
        exit 1
    fi

    if [ -z "${PEERTUBE_RUNNER_TOKEN}" ]
    then
        echo 'ERROR: Peertube runner token required to run container. Terminating...'
        exit 1
    fi
    
    export PEERTUBE_CONFIG_DIR="/home/peertube/.config/peertube-runner-nodejs/${PEERTUBE_RUNNER_NAME}"
    mkdir -p "${PEERTUBE_CONFIG_DIR}"
    
    # Create initial config file without registeredInstances
    cat > "${PEERTUBE_CONFIG_DIR}/${PEERTUBE_CONFIG}" <<EOF
[jobs]
concurrency = ${CONCURRENT_JOBS}

[ffmpeg]
threads = ${FFMPEG_THREADS}
nice = ${FFMPEG_NICE}

[transcription]
engine = "${PEERTUBE_TRANSCRIPTION_ENGINE}"
enginePath = "${PEERTUBE_TRANSCRIPTION_ENGINEPATH}"
model = "${PEERTUBE_TRANSCRIPTION_MODEL}"

EOF
    
fi


echo "Starting peertube runner now..."

# Setup trap to handle shutdown gracefully
trap_handler() {
    echo 'Termination command received. Deregistering runner and terminating...'
    if [ -n "${SERVER_PID:-}" ]; then
        npx peertube-runner unregister --id "${PEERTUBE_RUNNER_NAME}" --runner-name "${PEERTUBE_RUNNER_NAME}" --url "${PEERTUBE_URL}" 2>/dev/null || true
        kill "${SERVER_PID}" 2>/dev/null || true
    fi
    exit 0
}

trap trap_handler SIGTERM SIGINT

# Build job types argument if set
JOB_TYPES_ARG=""
if [ -n "${PEERTUBE_RUNNER_JOB_TYPES:-}" ]; then
    for job_type in ${PEERTUBE_RUNNER_JOB_TYPES}; do
        JOB_TYPES_ARG="${JOB_TYPES_ARG} --enable-job ${job_type}"
    done
fi

if ! grep -q "^\[\[registeredInstances\]\]" "${PEERTUBE_CONFIG_DIR}/${PEERTUBE_CONFIG}"; then
    echo "First run detected - starting server and registering..."

    # Start server in background
    npx peertube-runner server ${PEERTUBE_RUNNER_ADDITIONAL_ARGS} ${JOB_TYPES_ARG} --id "${PEERTUBE_RUNNER_NAME}" &
    SERVER_PID=$!
    
    # Wait for server to create socket
    echo "Waiting for server to start..."
    for i in {1..30}; do
        if [ -S "/home/peertube/.local/share/peertube-runner-nodejs/${PEERTUBE_RUNNER_NAME}/peertube-runner.sock" ]; then
            echo "Server started, registering runner..."
            break
        fi
        sleep 1
    done
    
    # Register the runner
    npx peertube-runner register \
        --id "${PEERTUBE_RUNNER_NAME}" \
        --url "${PEERTUBE_URL}" \
        --registration-token "${PEERTUBE_RUNNER_TOKEN}" \
        --runner-name "${PEERTUBE_RUNNER_NAME}" \
        --runner-description "${PEERTUBE_RUNNER_DESCRIPTION}"
    
    echo "Registration complete, runner is now active"
    
    # Wait for server process
    wait "${SERVER_PID}"
else
    # Already registered, just start server
    exec npx peertube-runner server ${PEERTUBE_RUNNER_ADDITIONAL_ARGS} ${JOB_TYPES_ARG} --id "${PEERTUBE_RUNNER_NAME}"
fi