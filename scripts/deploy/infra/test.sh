#!/bin/bash

oc delete CheCluster/devspaces -n openshift-devspaces
oc delete deploy/$(oc get deploy -n openshift-operators | grep webhook | cut -d ' ' -f1) -n openshift-operators
oc delete sa/$(oc get sa -n openshift-operators | grep webhook | cut -d ' ' -f1) -n openshift-operators
oc delete service/devworkspace-webhookserver -n openshift-operators
# This needs to be changed to iterate over the pods
#oc delete pod/$(oc get pod -n openshift-devspaces | cut -d ' ' -f1) -n openshift-devspaces
oc delete ns/openshift-devspaces
CSV=$(oc get sub devworkspace-operator-fast-redhat-operators-openshift-marketplace -n openshift-operators -o json | jq -r '.status.installedCSV')
oc delete sub devworkspace-operator-fast-redhat-operators-openshift-marketplace -n openshift-operators
oc delete csv ${CSV} -n openshift-operators
CSV=$(oc get sub devspaces -n openshift-operators -o json | jq -r '.status.installedCSV')
oc delete sub devspaces -n openshift-operators
oc delete csv ${CSV} -n openshift-operators
oc delete crd checlusters.org.eclipse.che
oc delete crd devworkspaceoperatorconfigs.controller.devfile.io
oc delete crd devworkspaceroutings.controller.devfile.io
oc delete crd devworkspaces.workspace.devfile.io
oc delete crd devworkspacetemplates.workspace.devfile.io
oc delete operator devworkspace-operator.openshift-operators
oc delete operator devspaces.openshift-operators
