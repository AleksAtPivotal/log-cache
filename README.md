# Log Cache

## Create Kubernetes Namespace
```
export LOGCACHENS=logcache
kubectl create ns $LOGCACHENS
```

## Create TLS Secret for K8s

```
docker run -v "$PWD/output:/output" loggregator/certs
kubectl create -n $LOGCACHENS secret generic tls --from-file=$PWD/output
```

## Deploy Log-Cache

```
kubectl -n $LOGCACHENS  create -f ./kubernetes
```

## Scale
```
kubectl -n $LOGCACHENS  scale statefulset logcache --replicas=2
```