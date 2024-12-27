Icecast (set up container once to listen for input):
docker run -d -p 8000:8000 -v ./icecast.xml:/etc/icecast.xml --network sm2 --network-alias icecast libretime/icecast:2.4.4-debian

Liquidsoap (run at CLI as needed for testing, verbose mode in LiquidSoap):
docker run --rm -w /test -v "$(pwd):/test" --network sm2 savonet/liquidsoap:v2.3.0 -v StationManager2.liq -- stationconfig.json