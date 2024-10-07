#!/bin/bash

if [ ${#DEPLOY_EVERYTHING} -eq 0 ]; then
  clear
  source ../../common_cfg
fi

# paths
BASE_PATH=../../../yaml
CLUSTER_OP_PATH=${BASE_PATH}/DevSpaces
CLUSTER_OP_NS=openshift-operators
CLUSTER_OP_NAME=devspaces.openshift-operators
CHE_CLUSTER_NS=openshift-devspaces

LOGIN_PARMS=$(getLoginString ${KUBEADMIN_USER})
failChk oc login ${LOGIN_PARMS} > /dev/null

# Deploying the cluster operator
# ------------------------------------------------------------------
echo "Deploying OpenShift Dev Spaces cluster operator..."
failChk oc create -f ${CLUSTER_OP_PATH}/devspaces_sub.yaml

# Wait for deployment success
echo "Waiting for operators to install and be at latest version..."
subscriptionNames=("devspaces"  "devworkspace-operator-fast-redhat-operators-openshift-marketplace")
size=${#subscriptionNames[@]}

for NAME in ${subscriptionNames[*]}; do
  AVAILABLE="0"

  while [ "${AVAILABLE}" != "AtLatestKnown" ]; do
    sleep 1
    AVAILABLE=$(oc get sub ${NAME} -n ${CLUSTER_OP_NS} -o json | jq -r '.status.state')
  done
  echo "  Subscription '${NAME}' is up to date"
done
  
# Wait for deployment success
echo "Waiting for deployments to become available..."
deploymentNames=("devspaces-operator"  "devworkspace-controller-manager"  "devworkspace-webhook-server")
deploymentCounts=("1"  "1"  "2")
size=${#deploymentNames[@]}

for (( i=0; i<${size}; i++ )); do
  AVAILABLE="0"
  NAME=${deploymentNames[$i]}
  TOTAL_DEPLOYMENTS=${deploymentCounts[$i]}
  
  while [ "${AVAILABLE}" != "${TOTAL_DEPLOYMENTS}" ]; do
    sleep 1
    AVAILABLE=$(oc get deployments -n ${CLUSTER_OP_NS} 2>/dev/null | grep ${NAME} | tr -s ' ' | cut -d ' ' -f4)
  done
  echo "  Deployment '${NAME}' is ready"
done

echo "Deploying the Che Cluster..."
failChk oc create -f ${CLUSTER_OP_PATH}/che_cluster.yaml

# Wait for deployment success
echo "Waiting for deployments to become available..."
# use trailing whitespace to distinguish between strings and substrings
deploymentNames=("che-gateway"  "devspaces "  "devspaces-dashboard" "plugin-registry")
deploymentCounts=("1"  "1"  "1" "1")
size=${#deploymentNames[@]}

for (( i=0; i<${size}; i++ )); do
  AVAILABLE="0"
  NAME="${deploymentNames[$i]}"
  TOTAL_DEPLOYMENTS=${deploymentCounts[$i]}

  while [ "${AVAILABLE}" != "${TOTAL_DEPLOYMENTS}" ]; do
    sleep 1
    AVAILABLE=$(oc get deployments -n ${CHE_CLUSTER_NS} 2>/dev/null | grep "${NAME}" | tr -s ' ' | cut -d ' ' -f4)
  done
  # remove trailing whitespace before printing
  NAME=$(echo -e "${NAME}" | tr -d '[:space:]')
  echo "  Deployment '${NAME}' is ready"
done


