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
    cat > "${PEERTUBE_CONFIG_DIR}/${PEERTUBE_CONFIG}" <<EOF
[jobs]
concurrency = ${FFMPEG_CONCURRENT_JOBS}

[ffmpeg]
threads = ${FFMPEG_THREADS}
nice = ${FFMPEG_NICE}

[transcription]
engine = "${PEERTUBE_TRANSCRIPTION_ENGINE}"
enginePath = "${PEERTUBE_TRANSCRIPTION_ENGINEPATH}"
model = "${PEERTUBE_TRANSCRIPTION_MODEL}"

[registeredInstances]
url = "${PEERTUBE_URL}"
runnerToken = "${PEERTUBE_RUNNER_TOKEN}"
runnerName = "${PEERTUBE_RUNNER_NAME}"
runnerDescription = "${PEERTUBE_RUNNER_DESCRIPTION}"    

EOF
    
fi


echo "Starting peertube runner now..."

# Start server in background to allow registration
npx peertube-runner server ${PEERTUBE_RUNNER_ADDITIONAL_ARGS} --id "${PEERTUBE_RUNNER_NAME}" &
SERVER_PID=$!

# Wait for server to be ready
sleep 2s

# Register the runner
npx peertube-runner register --id "${PEERTUBE_RUNNER_NAME}" --runner-name "${PEERTUBE_RUNNER_NAME}" --url "${PEERTUBE_URL}" --registration-token "${PEERTUBE_RUNNER_TOKEN}"

# Setup trap to handle shutdown gracefully
trap "echo 'Termination command received. Deregistering runner and terminating...'; npx peertube-runner unregister --id '${PEERTUBE_RUNNER_NAME}' --runner-name '${PEERTUBE_RUNNER_NAME}' --url '${PEERTUBE_URL}'; kill ${SERVER_PID}; exit 0" SIGTERM SIGINT

# Wait for server process
wait ${SERVER_PID}