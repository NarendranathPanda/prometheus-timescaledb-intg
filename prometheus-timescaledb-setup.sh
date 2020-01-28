// Installation of docker 
// update the existing software
yum update -y

// Docker Installataion :  https://docs.docker.com/install/linux/docker-ce/centos/
sudo yum-config-manager \
	--add-repo \
	https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
docker info
docker ps
// ----------------------------------------
// Complete Demo set up 

// 0. Connectivity : Docker Network
// 1. Remote DB    : timescale/pg_prometheus 
// 2. Adapter      : prometheus-postgresql-adapter
// 3. Targets      : node-expoter
 
// Create a dedicated network 
docker network create -d bridge prometheus_timescale_network

// create remote pg timescale DB 
docker run --network prometheus_timescale_network  --name pg_prometheus \
     -e POSTGRES_PASSWORD=secret -d -p 5432:5432 timescale/pg_prometheus:latest-pg11 postgres \
     -csynchronous_commit=off

// create pg adapter container
docker run --network prometheus_timescale_network --name prometheus_postgresql_adapter -d -p 9201:9201 \
timescale/prometheus-postgresql-adapter:latest \
-pg-host=pg_prometheus \
-pg-password=secret \
-pg-prometheus-log-samples	

//  create metric collection target: node_exporter  
docker run --network prometheus_timescale_network --name node_exporter -p 9100:9100 quay.io/prometheus/node-exporter

// Create Prometheus container and fix the prometheus.yaml 
vi prometheus.yaml
// =========================
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

// ========================================
docker run --network prometheus_timescale_network -p 9090:9090 -v ${PWD}/prometheus.yml:/etc/prometheus/prometheus.yml \
      prom/prometheus
	  
// Testing / Demo time 

// Check all the container 
docker ps 

// Check the prometheus instance 
http:localhost:9090/graph

// check the metrics 
node_network_transmit_bytes_total


//check the postgade db 
docker exec -it pg_prometheus bash
psql postgres postgres

//list of tables/views
\d 

//list of tables
\dt

\d metrics_values

//sample table 
SELECT time, value AS "total transmitted bytes" FROM metrics WHERE labels->>'device' = 'eth0' AND name='node_network_transmit_bytes_total' ORDER BY time;
