oc new-project prometheus-example
oc new-app prom/prometheus
cat <<'EOF' > prometheus.yml
global:
 scrape_interval:     10s
 evaluation_interval: 10s
scrape_configs:
 - job_name: prometheus
   static_configs:
     - targets: ['node_exporter:9100']
remote_write:
 - url: "http://prometheus_postgresql_adapter:9201/write"
remote_read:
 - url: "http://prometheus_postgresql_adapter:9201/read"

oc create configmap prom-config-example --from-file=prometheus.yml

oc edit dc/prometheus
####### Add to volume section 
- name: prom-config-example-volume
   configMap:
     name: prom-config-example
     defaultMode: 420
####### Add to the mount section 
- name: prom-config-example-volume
  mountPath: /etc/prometheus/


oc create secret generic my-secret --from-literal=POSTGRES_PASSWORD=secret  
oc new-app --docker-image="timescale/pg_prometheus:latest-pg11" --source-secret=my-secret --allow-missing-images

oc new-app --docker-image="timescale/prometheus-postgresql-adapter:latest" -e pg-host=pg_prometheus -e pg-password=secret




  
  
  
  
