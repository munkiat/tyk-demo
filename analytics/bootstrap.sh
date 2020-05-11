#!/bin/bash

source scripts/common.sh
feature="Analytics"
log_start_feature
bootstrap_progress

kibana_base_url="http://localhost:5601"
kibana_status=""
kibana_status_desired="200"

log_message "Waiting for kibana to return desired response"
while [ "$kibana_status" != "$kibana_status_desired" ]
do
  kibana_status=$(curl -I -s -m5 $kibana_base_url/app/kibana 2>> bootstrap.log | head -n 1 | cut -d$' ' -f2)  
  if [ "$kibana_status" != "$kibana_status_desired" ]
  then
    log_message "  Request unsuccessful, retrying..."
    sleep 2
  else
    log_ok
  fi
  bootstrap_progress
done

log_message "Adding index pattern"
log_http_result "$(curl $kibana_base_url/api/saved_objects/index-pattern/1208b8f0-815b-11ea-b0b2-c9a8a88fbfb2?overwrite=true -s -o /dev/null -w "%{http_code}" \
  -H 'Content-Type: application/json' \
  -H 'kbn-xsrf: true' \
  -d @analytics/data/kibana/index-patterns/tyk-analytics.json 2>> bootstrap.log)"
bootstrap_progress

log_message "Adding visualisation"
log_http_result "$(curl $kibana_base_url/api/saved_objects/visualization/407e91c0-8168-11ea-9323-293461ad91e5?overwrite=true -s -o /dev/null -w "%{http_code}" \
  -H 'Content-Type: application/json' \
  -H 'kbn-xsrf: true' \
  -d @analytics/data/kibana/visualizations/request-count-by-time.json 2>> bootstrap.log)"
bootstrap_progress

log_message "Stopping the pump instance deployed by the base deployment"
# so it is replaced by the instance from this deployment
docker-compose stop tyk-pump 2>/dev/null
log_ok
bootstrap_progress

log_message "Sending a test request to provide Kibana with data"
# since request sent in base bootstrap process will not have been picked up by elasticsearch-enabled pump
log_http_result "$(curl -s localhost:8080/basic-open-api/get -o /dev/null -w "%{http_code}" 2>> bootstrap.log)"

log_end_feature

echo -e "\033[2K
▼ Analytics
  ▽ Kibana
               URL : $kibana_base_url"