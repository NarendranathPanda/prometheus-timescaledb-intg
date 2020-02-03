oc new-project oc-prometheus-timescaledb-setup
oc new-app prom/prometheus --name=demo-prom

cat <<'EOF' > prometheus.yml
global:
 scrape_interval:     10s
 evaluation_interval: 10s
scrape_configs:
 - job_name: prometheus
   static_configs:
     - targets: ['node_exporter:9100']
remote_write:
 - url: "http://prometheus-postgresql-adapter:9201/write"
remote_read:
 - url: "http://prometheus-postgresql-adapter:9201/read"

oc create configmap prom-config --from-file=prometheus.yml
oc volume dc/prometheus --add --name=prom-k8s -m /etc/prometheus -t configmap --configmap-name=prom-config
oc expose service demo-prom

oc create secret generic pg-secret --from-literal=POSTGRES_PASSWORD=secret  
oc new-app --docker-image="timescale/pg_prometheus:latest-pg11" --source-secret=pg-secret --allow-missing-images --name=pg-prometheus
oc expose service pg-prometheus

oc new-app --docker-image="timescale/prometheus-postgresql-adapter:latest" -e pg-host=pg-prometheus -e pg-password=secret --name=prometheus-postgresql-adapter
oc expose service prometheus-postgresql-adapter




  
  
  
  
