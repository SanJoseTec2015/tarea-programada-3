#!/bin/sh
make #> /dev/null
echo "\n"
./stacktest prueba #> output #| tee output
echo "\n"
