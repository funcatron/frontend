#!/bin/bash

export INSTANCEID="R-${RANDOM}-${RANDOM}-${RANDOM}-${RANDOM}-${RANDOM}"

if [[ "$1" == "dev" ]]; then
    sed s/#DEV#//g /usr/local/openresty/nginx/conf/nginx.conf > /tmp/nginx.conf
    cp /tmp/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
    echo "Running in dev mode. Point your browser to http://localhost:8780"
    export DEV_MODE="TRUE"
fi



if [ ! -z "$MESOS_TASK_ID" ]; then
    echo "It's a Meso substrate, so discover _stomp._rabbit-funcatron._tcp.marathon.mesos" 1>&2

    HOST=""
    PORT=""

    host () {
        HOST=$(dig _rabbit-funcatron._tcp.marathon.mesos SRV | \
                      grep "IN A" | grep -v "^\;" | \
                      grep -o "[0-9]*\.[0-9]*\.[[0-9]*\.[0-9]*$" | \
                      sed -n 1p)
    }

    port () {
        PORT=$(dig _stomp._rabbit-funcatron._tcp.marathon.mesos SRV | \
                      grep -v "^\;" | grep -e "IN\s\+SRV" | \
                      grep -o "[0-9]* *[^ ]*$" | \
                      grep -o "^[0-9]*" | sed -n 1p)
    }

    while [[ -z "$PORT" || -z "$HOST" ]] ; do
        echo "In host/port loop: Host: $HOST, Port: $PORT" 1>&2
        sleep 1
        host
        port
    done

    export RABBIT_HOST=$HOST
    export RABBIT_PORT=$PORT

    echo "Discovered the port... starting OpenResty" 1>&2
    #while [ true ] ; do
    #    echo "Hello Marathon $HOST $PORT" >&2
    #    sleep 5
    #done
else
    echo "Not in an orchestration env... that we know of..." 1>&2
fi

echo "Starting OpenResty"

/usr/local/openresty/bin/openresty -g "daemon off;"
