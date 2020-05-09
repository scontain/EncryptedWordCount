FROM sconecuratedimages/kubernetes:hello-k8s-scone0.1

MAINTAINER Christof Fetzer "christof.fetzer@scontain.com"

COPY encrypted-files /fspf/encrypted-files
COPY fspf-file/fs.fspf /fspf/fs.fspf
