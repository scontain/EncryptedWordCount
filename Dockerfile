FROM sconecuratedimages/apps:pypy-2.7.15-alpine3.7

MAINTAINER Christof Fetzer "christof.fetzer@scontain.com"

COPY encrypted-files /fspf/encrypted-files
COPY fspf-file/fs.fspf /fspf/fs.fspf
