#!/bin/bash -e
#
# Copyright IT People Corporation. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

##TODO: add debug flag to enable/disable for peer ad orderer
## usage message
function usage () {
  echo "Usage: "
  echo "  bootstrap.sh [-m start|stop|restart] [-t <release-tag>] [-c enable-CouchDB] [-l capture-logs]"
  echo "  bootstrap.sh -h|--help (print this message)"
  echo "      -m <mode> - one of 'start', 'stop', 'restart' " #or 'generate'"
  echo "      - 'start' - bring up the network with docker-compose up & start the app on port 3000"
  echo "      - 'up'    - same as start"
  echo "      - 'stop'  - stop the network with docker-compose down & clear containers , crypto keys etc.,"
  echo "      - 'down'  - same as stop"
  echo "      - 'restart' -  restarts the network and start the app on port 3000 (Typically stop + start)"
  echo "     -c enable CouchDB"
  echo "     -r re-Generate the certs and channel artifacts"
  echo "     -l capture docker logs before network teardown"
  echo "     -t <release-tag> - ex: alpha | beta | rc , missing this option will result in using the latest docker images"
  echo
  echo "Some possible options:"
  echo
  echo "	bootstrap.sh"
  echo "	bootstrap.sh -l"
  echo "	bootstrap.sh -r"
  echo "	bootstrap.sh -m restart -t 1.4.3"
  echo "	bootstrap.sh -m start -c"
  echo "	bootstrap.sh -m stop"
  echo "	bootstrap.sh -m stop -l"
  echo
  echo "All defaults:"
  echo "	bootstrap.sh"
  echo "	RESTART the network/app, use latest docker images but TAG, Disable couchdb "
  exit 1
}
#### Banner


: ${MODE:="restart"}
: ${IMAGE_TAG:="2.2.0"}
: ${IMAGE_TAG_CA:="latest"}
: ${COUCHDB:="y"}
: ${ENABLE_LOGS:="n"}
: ${TIMEOUT:="45"}

export THIRDPARTY_IMAGE_TAG="0.4.18" ## this has to match with the  version
export ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

# Parse commandline args
while getopts "h?m:t:clr" opt; do
  case "$opt" in
    h|\?)
      usage
      exit 1
    ;;
    m)  MODE=$OPTARG
    ;;
    c)  COUCHDB='y'
    ;;
    l)  ENABLE_LOGS='y'
    ;;
    r)  REGENERATE='y'
    ;;
    t)  IMAGE_TAG="$OPTARG"
	##TODO: ensure package.json contains right node packages
    ;;
  esac
done
export IMAGE_TAG
export IMAGE_TAG_CA


function checkForDockerImages() {
	DOCKER_IMAGES=$(docker images | grep "$IMAGE_TAG\|$IMAGE_TAG_CA\|$THIRDPARTY_IMAGE_TAG" | grep -v "amd" | wc -l)
	if [ $DOCKER_IMAGES -ne 6 ]; then
		printf "\n############# You don't have all fabric images, Let me pull them for you ###########\n"
		echo "===> Pulling fabric ca Image"
		for IMAGE in ca; do
		      docker pull hyperledger/fabric-$IMAGE:$IMAGE_TAG_CA
		done
		printf "######## Pulling Fabric Images ... ########\n"
		for IMAGE in peer orderer ccenv tools; do
		      docker pull hyperledger/fabric-$IMAGE:$IMAGE_TAG
		done
		printf "######## Pulling 3rdParty Images ... ########\n"
		for IMAGE in couchdb; do
		      docker pull hyperledger/fabric-$IMAGE:$THIRDPARTY_IMAGE_TAG
		done
	fi
}

function startNetwork() {
	LOCAL_DIR=$PWD
	printf "\n ========= FABRIC IMAGE TAG : $IMAGE_TAG ===========\n"
   	 checkForDockerImages

	### Let's not worry about dynamic generation of Org certs and channel artifacts
	if [ "$REGENERATE" = "y" ]; then
		echo "===> Downloading platform binaries"
		rm -rf bin
		wget https://github.com/hyperledger/fabric/releases/download/v${IMAGE_TAG}/hyperledger-fabric-${ARCH}-${IMAGE_TAG}.tar.gz
		tar xvf hyperledger-fabric-${ARCH}-${IMAGE_TAG}.tar.gz
		rm -rf hyperledger-fabric-${ARCH}-${IMAGE_TAG}.tar.gz
	fi

	#Launch the network
	cd customerloyalty-network/
	sudo ./network.sh up -s couchdb
	sudo ./network.sh createChannel
	sudo ./network.sh deployCC -l javascript
	
}

function shutdownNetwork() {
	cd customerloyalty-network/
	sudo ./network.sh down
  cd ../
}

#Launch the network using docker compose
case $MODE in
	'start'|'up')
		startNetwork
	;;
	'restart')
    shutdownNetwork
    startNetwork
	;;
	*)
		usage
	;;
esac
