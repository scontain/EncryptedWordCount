#!/bin/bash
#
# tasks performed:
#
# - creates a local Docker image with an encrypted Python program (wordcount) and encrypted input file
# - pushes a new session to a CAS instance
# - creates a file with the session name
#
# show what we do (-x), export all varialbes (-a), and abort of first error (-e)

set -x -a -e
trap "echo Unexpected error! See log above; exit 1" ERR

# CONFIG Parameters (might change)

export CAS_ADDR=scone-cas.cf

export SCONE_CAS_IMAGE="sconecuratedimages/services:cas"
# Not nessecarily access to CAS image, add default
export CAS_MRENCLAVE=`(docker pull $SCONE_CAS_IMAGE > /dev/null ; docker run -i --rm -e "SCONE_HASH=1" $SCONE_CAS_IMAGE cas) || echo 9a1553cd86fd3358fb4f5ac1c60eb8283185f6ae0e63de38f907dbaab7696794`  # compute MRENCLAVE for current CAS

export CLI_IMAGE="sconecuratedimages/kubernetes:hello-k8s-scone0.1"
export PYTHON_IMAGE="sconecuratedimages/kubernetes:hello-k8s-scone0.1"

export PYTHON_MRENCLAVE=`docker pull $PYTHON_IMAGE > /dev/null ; docker run -i --rm -e "SCONE_HASH=1" $PYTHON_IMAGE python`

# create random and hence, uniquee session number
SESSION="Session-$RANDOM-$RANDOM-$RANDOM"

# create directories for encrypted files and fspf
rm -rf encrypted-files
rm -rf fspf-file
mkdir encrypted-files/
mkdir fspf-file/
cp fspf.sh fspf-file

# ensure that we have an up-to-date image
docker pull $CLI_IMAGE

# attest cas before uploading the session file, accept CAS running in debug
# mode (-d) and outdated TCB (-G)
docker run --device=/dev/isgx -it $CLI_IMAGE sh -c "
scone cas attest -G --only_for_testing-debug  scone-cas.cf $CAS_MRENCLAVE >/dev/null \
&&  scone cas show-certificate" > cas-ca.pem

# create encrypte filesystem and fspf (file system protection file)
docker run --device=/dev/isgx  -it -v $(pwd)/fspf-file:/fspf/fspf-file -v $(pwd)/native-files:/fspf/native-files/ -v $(pwd)/encrypted-files:/fspf/encrypted-files $CLI_IMAGE /fspf/fspf-file/fspf.sh

cat >Dockerfile <<EOF
FROM $PYTHON_IMAGE

MAINTAINER Christof Fetzer "christof.fetzer@scontain.com"

COPY encrypted-files /fspf/encrypted-files
COPY fspf-file/fs.fspf /fspf/fs.fspf
EOF

# create a wordcount image with encrypted wordcount.py
docker build --pull -t wordcount .

# ensure that we have self-signed client certificate

if [[ ! -f client.pem || ! -f client-key.pem  ]] ; then
    openssl req -newkey rsa:4096 -days 365 -nodes -x509 -out client.pem -keyout client-key.pem -config clientcertreq.conf
fi

# create session file

export SCONE_FSPF_KEY=$(cat native-files/keytag | awk '{print $11}')
export SCONE_FSPF_TAG=$(cat native-files/keytag | awk '{print $9}')

MRENCLAVE=$PYTHON_MRENCLAVE envsubst '$MRENCLAVE $SCONE_FSPF_KEY $SCONE_FSPF_TAG $SESSION' < session-template.yml > session.yml
IP=$(host scone.ml | awk -p '{print $4}')
curl -v --cacert cas-ca.pem -s --cert client.pem  --key client-key.pem --resolve cas:8081:$IP --data-binary @session.yml -X POST https://cas:8081/session


# create file with environment variables

cat > myenv << EOF
export SESSION="$SESSION"
export SCONE_CAS_ADDR="$IP"
EOF

echo "OK"
