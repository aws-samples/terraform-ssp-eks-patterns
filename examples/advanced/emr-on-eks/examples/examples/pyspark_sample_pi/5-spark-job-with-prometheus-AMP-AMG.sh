#!/bin/bash
#  You can use pod template files to define the driver or executor pod’s configurations that Spark configurations do not support.
# see Pod Template (https://spark.apache.org/docs/3.0.0-preview/running-on-kubernetes.html#pod-template).

# INPUT VARIABLES 
EMR_ON_EKS_ROLE_ID="aws001-preprod-test-emr-eks-data-team-a"       # Replace EMR IAM role with your ID
EKS_CLUSTER_ID='aws001-preprod-test-eks'        # Replace cluster id with your id
EMR_ON_EKS_NAMESPACE='emr-data-team-a'                             # Replace namespace with your namespace
EMR_VIRTUAL_CLUSTER_NAME="$EKS_CLUSTER_ID-$EMR_ON_EKS_NAMESPACE"
JOB_NAME='taxidata'                                   

S3_BUCKET='s3://<enter-your-s3-bucket-name>'                   # Create your own s3 bucket and replace this value
CW_LOG_GROUP="/emr-on-eks-logs/${EMR_VIRTUAL_CLUSTER_NAME}/${EMR_ON_EKS_NAMESPACE}" # Create CW Log group if not exist
SPARK_JOB_S3_PATH="${S3_BUCKET}/${EMR_VIRTUAL_CLUSTER_NAME}/${EMR_ON_EKS_NAMESPACE}/${JOB_NAME}"

# Step1: COPY POD TEMPLATES TO S3 Bucket
aws s3 sync ./pyspark/ "${SPARK_JOB_S3_PATH}/"

# FIND ROLE ARN and EMR VIRTUAL CLUSTER ID 
EMR_ROLE_ARN=$(aws iam get-role --role-name $EMR_ON_EKS_ROLE_ID --query Role.Arn --output text)
VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${EMR_VIRTUAL_CLUSTER_NAME}' && state=='RUNNING'].id" --output text)

# Execute Spark job
if [[ $VIRTUAL_CLUSTER_ID != "" ]]; then
  echo "Found Cluster $EMR_VIRTUAL_CLUSTER_NAME; Executing the Spark job now..."
  aws emr-containers start-job-run \
    --virtual-cluster-id $VIRTUAL_CLUSTER_ID \
    --name $JOB_NAME \
    --execution-role-arn $EMR_ROLE_ARN \
    --release-label emr-6.3.0-latest \
    --job-driver '{
      "sparkSubmitJobDriver": {
        "entryPoint": "'"$SPARK_JOB_S3_PATH"'/scripts/spark-taxi-trip-data.py",
        "entryPointArguments": ["'"$SPARK_JOB_S3_PATH"'/input/taxi-trip-data/",
          "'"$SPARK_JOB_S3_PATH"'/output/taxi-trip-data/", "taxitripdata"
        ],
        "sparkSubmitParameters": "--conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=2 --conf spark.driver.cores=1 --conf spark.metrics.conf.*.sink.prometheusServlet.class=org.apache.spark.metrics.sink.PrometheusServlet --conf spark.metrics.conf.*.sink.prometheusServlet.path=/metrics/prometheus --conf master.sink.prometheusServlet.path=/metrics/master/prometheus --conf applications.sink.prometheusServlet.path=/metrics/applications/prometheus --conf spark.ui.prometheus.enabled=true --conf spark.executor.processTreeMetrics.enabled=true --conf spark.kubernetes.driver.annotation.prometheus.io/scrape=true --conf spark.kubernetes.driver.annotation.prometheus.io/path=/metrics/prometheus/ --conf spark.kubernetes.driver.annotation.prometheus.io/port=4040 --conf spark.kubernetes.driver.service.annotation.prometheus.io/scrape=true --conf spark.kubernetes.driver.service.annotation.prometheus.io/path=/metrics/executors/prometheus/ --conf spark.kubernetes.driver.service.annotation.prometheus.io/port=4040"
      }
   }' \
    --configuration-overrides '{
      "applicationConfiguration": [
          {
            "classification": "spark-defaults", 
            "properties": {
              "spark.hadoop.hive.metastore.client.factory.class":"com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory",
              "spark.driver.memory":"2G",
              "spark.kubernetes.executor.podNamePrefix":"taxidata-executor"
            }
          }
        ], 
      "monitoringConfiguration": {
        "persistentAppUI":"ENABLED",
        "cloudWatchMonitoringConfiguration": {
          "logGroupName":"'"$CW_LOG_GROUP"'",
          "logStreamNamePrefix":"'"$JOB_NAME"'"
        }
      }
    }'
else
  echo "Cluster is not in running state $EMR_VIRTUAL_CLUSTER_NAME"
fi

