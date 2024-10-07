#!/bin/bash

if [ ${#DEPLOY_EVERYTHING} -eq 0 ]; then
  clear
  source ../../common_cfg
fi

function getSeconds()
  {
    unit=${1: -1}
    val=${1:0:-1}

    factor=1
    if [ "${unit}" == "m" ];then
      factor=60
    fi

    echo "$((val * factor))"
  }

function getTotalSeconds()
  {
    numVal=0
    count=$(echo ${SINCE} | tr -cd '[:alpha:]' | wc -m)
    
    for (( c=1; c<=${count}; c++ ))
    do 
      strVal=$(echo ${SINCE} | sed -E 's/^([0-9][0-9]*)([a-z]).*/\1\2/')
      strVal=$(getSeconds ${strVal})
      #echo "strVal=${strVal}"
      numVal=$((numVal + strVal))
      SINCE=$(echo ${SINCE} | sed -E 's/^[0-9][0-9]*[a-z]//')
    done
    echo ${numVal}
  }

HTPASSWD_SECRET_NAME="htpasswd-custom-secret"

# paths
SCRIPT_PATH=$(pwd)
BASE_PATH=../../../yaml
CLUSTER_OP_PATH=${BASE_PATH}/rhoai
OCP_AUTH_CFGS=${BASE_PATH}/ocp_auth

LOGIN_PARMS=$(getLoginString ${KUBEADMIN_USER})
failChk oc login ${LOGIN_PARMS} > /dev/null

# Add admin user
# ------------------------------------------------------------------
echo "Adding new admin user..."

# create scratch dir
mkdir scratch

# create htpass file
echo "  Generating htpasswd file with new user..."
htpasswd -c -B -b scratch/users.htpasswd ${ADMIN_USER} ${ADMIN_PASS} > /dev/null

# create secret
echo "  Creating secret from htpasswd file..."
oc create secret generic ${HTPASSWD_SECRET_NAME} --from-file=htpasswd=scratch/users.htpasswd -n openshift-config > /dev/null

# verify you created a secret/htpasswd-secret object in openshift-config project
SECRET_NAME=$(oc get secret/${HTPASSWD_SECRET_NAME} --no-headers -n openshift-config | cut -d ' ' -f1)

if [ "${SECRET_NAME}" == "${HTPASSWD_SECRET_NAME}" ];then
  echo "  - htpasswd secret created successfully"
fi

# remove scratch dir
rm -rf scratch

# backup the default oAuth configuration
rm -rf ${OCP_AUTH_CFGS}
mkdir ${OCP_AUTH_CFGS}
oc get oauth cluster -o yaml > ${OCP_AUTH_CFGS}/oauth.yaml.bak

# clean up yaml
sed -i -e '/^metadata:/,/^  name:/{/^metadata:/!{/^  name:/!d}}' \
       -e '/^  name:/,/^spec:/{/^  name:/!{/^spec:/!d}}' \
       ${OCP_AUTH_CFGS}/oauth.yaml.bak

# modify oath to add new identity provider
cat ${OCP_AUTH_CFGS}/oauth.yaml.bak | sed -e 's/^  templates:/  - htpasswd: \
      fileData: \
        name: '"${HTPASSWD_SECRET_NAME}"' \
    mappingMethod: claim \
    name: localusers \
    type: HTPasswd \
  templates:/' > ${OCP_AUTH_CFGS}/oauth.yaml

# Capture 'updated since' value of auth clusteroperator
SINCE=$(oc get co authentication --no-headers 2>/dev/null | tr -s ' ' | cut -d ' ' -f6)
START_TIME=$(getTotalSeconds ${SINCE})
echo "  - start time: ${START_TIME}"

# adding the identity provider the default OAuth configuration
echo "  Adding htpasswd identity provider to oAuth config..."
failChk oc apply -f ${OCP_AUTH_CFGS}/oauth.yaml > /dev/null 2>&1

# Waiting for the account to resolve
echo "  Waiting for the authentication clusteroperator to reload..."
END_TIME=9999
while [ $((START_TIME < END_TIME)) == 1 ]; do
  SINCE=$(oc get co authentication --no-headers 2>/dev/null | tr -s ' ' | cut -d ' ' -f6)
  END_TIME=$(getTotalSeconds ${SINCE})
  sleep 1
done
echo "  - Reload complete"
echo "  - end time: ${END_TIME}"

# Adding the new admin user to cluster-admin role
echo "  Adding new user to cluster-admin role..."
failChk oc adm policy add-cluster-role-to-user cluster-admin ${ADMIN_USER} > /dev/null 2>&1
sleep 5
MSG=$(oc get co authentication --no-headers 2>/dev/null | tr -s ' ' | cut -d ' ' -f7)
while [ "${MSG}" != "" ]; do
  MSG=$(oc get co authentication --no-headers 2>/dev/null | tr -s ' ' | cut -d ' ' -f7)
  sleep 1
done

echo "Complete"

