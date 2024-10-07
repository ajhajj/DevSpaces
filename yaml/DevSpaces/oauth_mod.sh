#!/bin/bash

clear
cat oauth.yaml | sed -e 's/^  templates:/  - htpasswd: \
      fileData: \
        name: users \
    mappingMethod: claim \
    name: localusers \
    type: HTPasswd \
  templates:/'
