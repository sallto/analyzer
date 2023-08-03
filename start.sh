#!/bin/bash
set -e
#export NODE_OPTIONS=--openssl-legacy-provider
rm -rf run
eval $(opam env)
make
dune build gobview
./goblint --conf conf/examples/medium-program.json --enable gobview -v $1
cd run
python3 -m http.server
cd ..
