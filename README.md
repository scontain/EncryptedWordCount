# SCONE CAS: Encrypted Python Code and Input Demo

This repository contains a simple encrypted `wordcount` demo
written in Python. **Both the `wordcount`code as well as the input is encrypted.** 

In this demo, we put both the Python code as well as the input file of the `wordcount` in the same encrypted filesystem. Typically, we would put the Python code in the encrypted filesystem of the image and the encrypted input and output files in one or more **encrypted volumes** mapped into the container.

## Limitations of this Demo

**NOTE**: *In this demo, we use an unencrypted Python base image, i.e., the standard Python libraries are not encrypted. Moreover, the Python engine runs inside of a debug enclave. [Contact us](mailto:info@scontain.com), if you need a production-ready Python engine with an encrypted Python libraries.*

## Prerequisites

This demo uses private docker repo images. To get access to these images for evaluation, please send us an [email](mailto:info@scontain.com?Subject=Access%20to%20SCONE%20wordcount%20demo&Body=Hi%20there%2c%0dmy%20Docker%20Hub%20ID%20is%20...%20and%20I'm%20working%20on%20...%20at%20company%20...%20and%20I%20would%20like%20to%20get%20access%20to%20the%20Scone%20wordcount%20images.%0dBest%20regards%2c%20...).

## Creating Image with Encrypted `wordcount`

After getting access to the base Python image, you can perform the following steps:

- Create a local docker image by executing the following shell script:

```bash
./create_image.sh
```

This creates a local image `encryptedwordcount` and a session in a SCONE Configuration and Attestation Service (CAS).

*We assume in this demo that the creation of the `wordcount` image is performed on a trusted host.* 
The execution of the `wordcount` can be performed on an untrusted host.

## Running the `wordcount` image

```bash
source myenv
docker-compose up
```

Ensure to execute

```bash
./cleanup.sh
```

## Contact

&copy; [scontain.com](http://www.scontain.com), 2020. [Questions or Suggestions?](mailto:info@scontain.com)
