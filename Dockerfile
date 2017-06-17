FROM ibmcom/swift-ubuntu-runtime:3.0.2
MAINTAINER IBM Swift Engineering at IBM Cloud
LABEL Description="Template Dockerfile that extends the ibmcom/swift-ubuntu-runtime image."

# We can replace this port with what the user wants
# EXPOSE {{PORT}}
EXPOSE 8080

# Linux OS utils
RUN apt-get update

ADD https://raw.githubusercontent.com/IBM-Swift/swift-ubuntu-docker/master/utils/run-utils.sh /root/utils/run-utils.sh
RUN chmod +x /root/utils/run-utils.sh
ADD https://raw.githubusercontent.com/IBM-Swift/swift-ubuntu-docker/master/utils/common-utils.sh /root/utils/common-utils.sh
RUN chmod +x /root/utils/common-utils.sh
