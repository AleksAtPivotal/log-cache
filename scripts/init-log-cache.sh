#! /bin/sh
set -euo pipefail
set -x

export LOGCACHE_SERVICE=log-cache-service
export LOGCACHE_SERVICE_PORT=8080
export LOGCACHE_CONFIGMAP=log-cache
export LOGCACHE_STATEFULSET=logcache
export LOGCACHE_SERVICE_DEPLOYMENT=logcache-scheduler

# Check for single replica
replicas=$(kubectl get statefulset $LOGCACHE_STATEFULSET -o json | jq '.spec.replicas')
if [[ $replicas -eq 1 ]]; then
    exit
else
    export endpointstring=""
    i=0
    while [ $i -lt $replicas ]
    do
    if [[ "$endpointstring" == "" ]] ; then
        export endpointstring=$LOGCACHE_STATEFULSET-0:$LOGCACHE_SERVICE_PORT
    else 
        export endpointstring=$endpointstring,$LOGCACHE_STATEFULSET-$i:$LOGCACHE_SERVICE_PORT
    fi
    let i=i+1
    done
fi
echo "Endpoints : $endpointstring"

# get Value from Configmap
configmap=$(kubectl get configmap $LOGCACHE_CONFIGMAP -o json | jq '.data.NODE_ADDRS' | tr -d '"' )
echo "ConfigMap value: $configmap"

# Check
if [[ "$endpointstring" != "$configmap" ]] ; then 
    echo "Updating Configmap"
    kubectl patch configmap $LOGCACHE_CONFIGMAP --patch '{"data": {"NODE_ADDRS": "'$endpointstring'"}}'
    kubectl patch statefulset $LOGCACHE_STATEFULSET --patch '{"spec": {"template": {"metadata": { "labels" : { "randomversion": "'$RANDOM'"}}}}}'
    kubectl patch deployment $LOGCACHE_SERVICE_DEPLOYMENT --patch '{"spec": {"template": {"metadata": { "labels" : { "randomversion": "'$RANDOM'"}}}}}'
fi
