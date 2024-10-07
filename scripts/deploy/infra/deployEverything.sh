#!/bin/bash

source ../../common_cfg

INSTALL_LOGFILE="./install.log"
DEPLOY_EVERYTHING="TRUE"
startTime=$(date +"%s")

# Seconds to wait before deploying next part
SETTLING_TIME=0

function bannerMsg()
  {
    sleep ${SETTLING_TIME}
    echo " "
    echo "=============================================="
    echo " $1"
    echo "=============================================="
    echo " "
  }

function pipedErrChck()
  {
    if [ ${PIPESTATUS[0]} -gt 0 ]; then
      echo "Failed $1" | tee ${INSTALL_LOGFILE}
      runTime=$(getRuntime)
      echo "Total run time: ${runTime}." | tee ${INSTALL_LOGFILE}
      echo " " | tee -a ${INSTALL_LOGFILE}
      exit 1
    fi
  }

function getRuntime()
  {
    endTime=$(date +"%s")
    duration=$(( endTime - startTime ))
    seconds=$((duration%60))
    minutes=$(((duration/60)%60))
    hours=$(((duration/3600)%24))
    runtime=""
    hrs=false
    min=false
    sec=false

    if [ ${hours} -gt 0 ]; then
      runtime="${hours} hours, "
      hrs=true
    fi
    if [ ${minutes} -gt 0 ] || ${hrs}; then
      runtime="${runtime}${minutes} min, "
    fi
    if [ ${seconds} -gt 0 ]; then
      runtime="${runtime}${seconds} seconds"
    fi

    echo "${runtime}"
  }

clear
bannerMsg "Deploying OpenShift Dev Spaces" | tee ${INSTALL_LOGFILE}
. ./deployDevSpaces.sh 2>&1 | tee -a ${INSTALL_LOGFILE}
pipedErrChck "Deploying OpenShift Dev Spaces"

SETTLING_TIME=5
bannerMsg "Deploying new admin user" | tee -a ${INSTALL_LOGFILE}
. ./deployAdminUser.sh 2>&1 | tee -a ${INSTALL_LOGFILE}
pipedErrChck "Deploying new admin user"

runTime=$(getRuntime)
echo "Total run time: ${runTime}" | tee -a ${INSTALL_LOGFILE}
echo " " | tee -a ${INSTALL_LOGFILE}

