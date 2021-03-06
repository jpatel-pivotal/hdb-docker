#!/bin/bash

sudo /usr/sbin/sshd



start_scdf_admin () {
  cd /data/
  if [ ! -z "`ps aux | grep spring-cloud-dataflow-server-local-1.1.0.BUILD-SNAPSHOT.jar | grep -v grep`" ]; then
    pid=$(ps aux | grep spring-cloud-dataflow-server-local-1.1.0.BUILD-SNAPSHOT.jar | grep -v grep | awk '{print $2}')
    echo "PID: ${pid}"
    kill -9 ${pid}
  fi
  java -jar spring-cloud-dataflow-server-local-1.1.0.BUILD-SNAPSHOT.jar \
  --spring.cloud.dataflow.applicationProperties.stream.spring.cloud.stream.kafka.binder.brokers=centos7-kafka:9092 \
  --spring.cloud.dataflow.applicationProperties.stream.spring.cloud.stream.kafka.binder.zkNodes=centos7-kafka:2181 > ~/scdf-admin.log &
}

start_scdf_shell () {
  cd /data/
  if [ -f demo.cmd ]; then
    rm -f demo.cmd
  fi
  sleep 30
  echo -e 'dataflow config server http://localhost:9393/' >> demo.cmd
  echo -e 'app import --uri http://bit.ly/stream-applications-kafka-maven' >> demo.cmd
  echo -e 'stream all destroy --force ' >> demo.cmd
  echo -e 'stream create --definition "http --server.port=9000 | scriptable-transform --script=""import groovy.json.JsonSlurper\ndef jsonCar = new JsonSlurper().parseText( payload )\ndef csvString = jsonCar.amountOfFuel + "","" + jsonCar.tankCapacity + "","" + jsonCar.currentMileage + "","" + jsonCar.currentGear + "","" + jsonCar.currentSpeed + "","" + jsonCar.currentRpm + "","" + jsonCar.eBrake + "","" + jsonCar.engTemp + "","" + jsonCar.insideTemp + "","" + jsonCar.outsideTemp + "","" + jsonCar.frontLeftPsi + "","" + jsonCar.frontRightPsi + "","" +jsonCar.rearLeftPsi + "","" + jsonCar.rearRightPsi + "","" + jsonCar.make + "","" + jsonCar.model + "","" + jsonCar.vin + "","" + jsonCar.year\nreturn csvString"" --language=groovy | hdfs --hdfs.fs-uri=hdfs://centos7-namenode:8020 --hdfs.directory=/demo --hdfs.file-name=demoData --hdfs.rollover=10000" --name demo --deploy' >> demo2.cmd
  echo -e 'stream create --definition "http --server.port=9000  | hdfs --hdfs.fs-uri=hdfs://centos7-namenode:8020 --hdfs.directory=/demo --hdfs.file-name=demoData --hdfs.file-extension=json --hdfs.rollover=10000" --name demo --deploy' >> demo.cmd
  echo 'script --file demo.cmd' | java -jar spring-cloud-dataflow-shell-*.BUILD-SNAPSHOT.jar



}


if [ "${HOSTNAME}" == "centos7-scdf-datanode1" ]; then
  echo "Will start scdf admin and shell on this node"
  start_scdf_admin
  start_scdf_shell
else
  echo "No scdf needed on this node"
fi
