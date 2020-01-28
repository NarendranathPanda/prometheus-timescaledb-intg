#Installation of docker 
	# update the existing software
	 yum update -y

	# https://docs.docker.com/install/linux/docker-ce/centos/


	sudo yum-config-manager \
		--add-repo \
		https://download.docker.com/linux/centos/docker-ce.repo

	sudo yum install docker-ce docker-ce-cli containerd.io


	sudo systemctl start docker

	docker info
	docker ps


----------------------------------------
Demo set up 

0. Network
1. timescale/pg_prometheus 
2. prometheus-postgresql-adapter
3. targets(node-expoter)
5. 

docker network create -d bridge prometheus_timescale_network

docker run --network prometheus_timescale_network  --name pg_prometheus \
     -e POSTGRES_PASSWORD=secret -d -p 5432:5432 timescale/pg_prometheus:latest-pg11 postgres \
     -csynchronous_commit=off
	 
docker run --network prometheus_timescale_network --name prometheus_postgresql_adapter -d -p 9201:9201 \
timescale/prometheus-postgresql-adapter:latest \
-pg-host=pg_prometheus \
-pg-password=secret \
-pg-prometheus-log-samples	

docker run --network prometheus_timescale_network --name node_exporter -p 9100:9100 quay.io/prometheus/node-exporter

vi prometheus.yaml
=========================
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

========================================

docker run --network prometheus_timescale_network -p 9090:9090 -v ${pwd}/prometheus.yml:/etc/prometheus/prometheus.yml \
      prom/prometheus
	  
http:localhost:9090
node_network_transmit_bytes_total

docker exec -it pg_prometheus bash
psql postgres postgres

# list of tables/views
\d 

#list of tables
\dt

#sample 

postgres=# \d metrics_values
                     Table "public.metrics_values"
  Column   |           Type           | Collation | Nullable | Default
-----------+--------------------------+-----------+----------+---------
 time      | timestamp with time zone |           | not null |
 value     | double precision         |           |          |
 labels_id | integer                  |           |          |
Indexes:
    "metrics_values_labels_id_idx" btree (labels_id, "time" DESC)
    "metrics_values_time_idx" btree ("time" DESC)
Triggers:
    ts_insert_blocker BEFORE INSERT ON metrics_values FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker()
Number of child tables: 1 (Use \d+ to list them.)


sample table 
SELECT time, value AS "total transmitted bytes" FROM metrics WHERE labels->>'device' = 'eth0' AND name='node_network_transmit_bytes_total' ORDER BY time;




 

