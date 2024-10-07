#!/bin/bash

if [ ${#DEPLOY_EVERYTHING} -eq 0 ]; then
  clear
  source ../../common_cfg
fi

HTPASSWD_SECRET_NAME="htpasswd-custom-secret"

# paths
SCRIPT_PATH=$(pwd)
BASE_PATH=../../../yaml
CLUSTER_OP_PATH=${BASE_PATH}/rhoai
OCP_AUTH_CFGS=${BASE_PATH}/ocp_auth

# remove admin user
# ------------------------------------------------------------------
echo "Removing htpasswd based admin user..."

# remove scratch dir
rm -rf scratch

LOGIN_PARMS=$(getLoginString ${KUBEADMIN_USER})
failChk oc login ${LOGIN_PARMS} > /dev/null

# remove admin role from new user
echo "  Removing role binding from htpasswd user..."
failChk oc adm policy remove-cluster-role-from-user cluster-admin ${ADMIN_USER} > /dev/null 2>&1

# remove htpasswd from oAuth
echo "  Removing htpasswd from oAuth..."
failChk oc apply -f ${OCP_AUTH_CFGS}/oauth.yaml.bak > /dev/null 2>&1
#failChk oc delete -f ${CLUSTER_OP_PATH}/htpasswd-cr.yaml

# Waiting for the account to resolve
echo "  Waiting for the authentication clusteroperator to reload..."
SINCE="never"
while [ "${SINCE}" != "0s" ]; do
  sleep 1
  SINCE=$(oc get co authentication --no-headers 2>/dev/null | tr -s ' ' | cut -d ' ' -f6)
done
echo "  - Reload complete"

# remove htpasswd file secret
echo "  Removing htpasswd file based secret..."
failChk oc delete secret ${HTPASSWD_SECRET_NAME} -n openshift-config > /dev/null 2>&1

