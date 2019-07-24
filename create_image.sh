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

export CAS_ADDR=scone.ml
export CAS_MRENCLAVE="ddfeb98b91c9d32abf532f21faa967186b992811b0d4da893bd029a12cef32c3"
export CLI_IMAGE="sconecuratedimages/iexec:cli-alpine"
export PYTHON_MRENCLAVE="cdf1365f51bc0b0193ba1e3c54e672efb45c361bca102e926b7251aaa9a926a8"

# create random and hence, uniquee session number
SESSION="Session-$RANDOM-$RANDOM-$RANDOM"

# create directories for encrypted files and fspf
rm -rf encrypted-files
rm -rf fspf-file
mkdir encrypted-files/
mkdir fspf-file/
cp fspf.sh fspf-file

# ensure that we have an up-to-date image
docker pull sconecuratedimages/iexec:cli-alpine

# attest cas before uploading the session file, accept CAS running in debug
# mode (-d) and outdated TCB (-G)
docker run -it $CLI_IMAGE scone cas attest --address $CAS_ADDR:8081 --mrenclave $CAS_MRENCLAVE -G -d > cas-ca.pem

# create encrypte filesystem and fspf (file system protection file)
docker run -it -v $(pwd)/fspf-file:/fspf/fspf-file -v $(pwd)/native-files:/fspf/native-files/ -v $(pwd)/encrypted-files:/fspf/encrypted-files $CLI_IMAGE /fspf/fspf-file/fspf.sh

# create a wordcount image with encrypted wordcount.py
docker build -t wordcount .

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
