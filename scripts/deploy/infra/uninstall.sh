#!/bin/bash

OPP_NS=openshift-operators
DEVSPACES_OP_CSV=$(oc get csv -n ${OPP_NS} 2>/dev/null | cut -d ' ' -f1 | grep "devspacesoperator")
WORKSPACE_OP_CSV=$(oc get csv -n ${OPP_NS} 2>/dev/null | cut -d ' ' -f1 | grep "devworkspace-operator")
oc delete operator devworkspace-operator.openshift-operators 2>/dev/null
oc delete operator devspaces.openshift-operators 2>/dev/null
oc delete csv ${DEVSPACES_OP_CSV} -n ${OPP_NS} 2>/dev/null
oc delete csv ${WORKSPACE_OP_CSV} -n ${OPP_NS} 2>/dev/null
oc delete sub devworkspace-operator-fast-redhat-operators-openshift-marketplace -n ${OPP_NS} 2>/dev/null
oc delete sub devspaces -n ${OPP_NS} 2>/dev/null

oc delete devworkspaces.workspace.devfile.io --all-namespaces --all --wait 2>/dev/null
oc delete devworkspaceroutings.controller.devfile.io --all-namespaces --all --wait 2>/dev/null
oc delete crd/devworkspaceroutings.controller.devfile.io 2>/dev/null
oc delete crd/devworkspaces.workspace.devfile.io 2>/dev/null
oc delete crd/devworkspacetemplates.workspace.devfile.io 2>/dev/null
oc delete deploy/devworkspace-webhook-server -n ${OPP_NS} 2>/dev/null
oc delete mutatingwebhookconfigurations controller.devfile.io 2>/dev/null
oc delete validatingwebhookconfigurations controller.devfile.io 2>/dev/null
oc delete all --selector app.kubernetes.io/part-of=devworkspace-operator 2>/dev/null
oc delete sa devworkspace-webhook-server -n ${OPP_NS} 2>/dev/null
oc delete configmap devworkspace-controller -n ${OPP_NS} 2>/dev/null
oc delete clusterrole devworkspace-webhook-server 2>/dev/null
oc delete clusterrolebinding devworkspace-webhook-server 2>/dev/null
