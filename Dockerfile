FROM registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.19-openshift-4.13 AS builder
WORKDIR /go/src/github.com/openshift/openshift-tests-private
COPY hack/builder.sh .
RUN bash builder.sh


FROM registry.ci.openshift.org/ocp/4.13:tools
COPY --from=builder /tmp/build/extended-platform-tests /usr/bin/
COPY --from=builder /tmp/build/handleresult.py /usr/bin/
RUN PACKAGES="git gzip zip util-linux openssh-clients httpd-tools skopeo" && \
    yum update -y && \
    sh -c 'echo -e "[rhel8.7-baseos]\nname=rhel8.7-baseos\nbaseurl=http://download-node-02.eng.bos.redhat.com/rhel-8/rel-eng/RHEL-8/latest-RHEL-8.7/compose/BaseOS/x86_64/os\nenabled=0\ngpgcheck=1" >/etc/yum.repos.d/rhel8.7-baseos.repo' && \
    yum -y --enablerepo=rhel8.7-baseos install sos && \
    yum install --setopt=tsflags=nodocs -y $PACKAGES && yum clean all && rm -rf /var/cache/yum/* && \
    git config --system user.name test-private && \
    git config --system user.email test-private@test.com && \
    chmod g+w /etc/passwd
RUN pip3 install --upgrade setuptools pip && pip3 install dotmap minio pyyaml==5.4.1 requests
RUN oc image extract quay.io/openshifttest/hypershift-client:latest --file=/hypershift && mv hypershift /usr/bin/ && chmod 755 /usr/bin/hypershift && \
    curl -s -L https://github.com/openshift/rosa/releases/download/v1.2.11/rosa-linux-amd64 -o /usr/bin/rosa && chmod 755 /usr/bin/rosa && rosa version && \
    oc image extract quay.io/openshifttest/oc-compliance:latest --file /tmp/oc-compliance && mv oc-compliance /usr/bin/ && chmod 755 /usr/bin/oc-compliance && \
    oc image extract quay.io/openshifttest/openshift4-tools:v1 --file=/tmp/OpenShift4-tools.tar && tar -C /opt -xf OpenShift4-tools.tar && rm -fr OpenShift4-tools.tar && \
    curl -s -k -L https://mirror2.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/latest-4.13/oc-mirror.tar.gz -o oc-mirror.tar.gz && tar -C /usr/bin/ -xzvf oc-mirror.tar.gz && chmod +x /usr/bin/oc-mirror && rm -f oc-mirror.tar.gz
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install -b /bin && \
    rm -rf ./aws awscliv2.zip
