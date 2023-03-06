#!/bin/bash

git clone https://xxx:xxxx@github.com/openshift/openshift-tests-private

cd openshift-tests-private && \
  make build && \
  mkdir -p /tmp/build && \
  cp pipeline/handleresult.py /tmp/build/handleresult.py && \
  cp bin/extended-platform-tests /tmp/build/extended-platform-tests