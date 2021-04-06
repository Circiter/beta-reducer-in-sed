#!/bin/sh

if [ "x$1" = x ]; then
    echo 'Usage: ./full-reduction.sh "<lambda_expression>"'
    exit
fi

expression="$1"

iterations=0
iterations_limit=1000

while true; do
    result="`echo "$expression" |  ./beta-reducer.sed`"
    iterations=$(( $iterations + 1 ))
    [ $iterations -ge $iterations_limit -o "x$result" = "x$expression" ] && break #working=0
    expression="$result"
done

echo "$result"
