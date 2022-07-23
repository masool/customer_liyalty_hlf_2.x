cd customerloyalty-network/
sudo ./network.sh down
sudo ./network.sh up -s couchdb
sudo ./network.sh createChannel
sudo ./network.sh deployCC -l javascript