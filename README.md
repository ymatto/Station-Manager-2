Create network "sm2"
    docker network create sm2

Icecast (set up container once to listen for input):
    docker run -d -p 8000:8000 -v ./icecast.xml:/etc/icecast.xml --network sm2 --network-alias icecast libretime/icecast:2.4.4-debian

Liquid Soap with test config (run at CLI as needed for testing, verbose mode in Liquid Soap):
    docker run --rm -p 1447:1447 -w /test -v "$(pwd):/test" --network sm2 -e "TZ=Etc/UTC" savonet/liquidsoap:v2.3.0 -v StationManager2.liq -- stationconfig.json

