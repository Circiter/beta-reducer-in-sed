#!/bin/sh

if [ "x$1" = x ]; then
    echo 'Usage: ./full-reduction.sh <program_filename>'
    echo '       echo <expression> | ./full-reduction.sh -'
    exit
fi

if [ "$1" = "-" ]; then
    expression="`cat`"
else
    expression="`cat $1`"
fi

iterations=0
iterations_limit=1000

# Preprocess.
expression="`echo "$expression" | ./preprocessor.sed`"

# Reduce.
while true; do
    result="`echo "$expression" |  ./beta-reducer.sed`"
    iterations=$(( $iterations + 1 ))
    [ $iterations -ge $iterations_limit -o "x$result" = "x$expression" ] && break
    expression="$result"
done

# Run the beta-reduce.sed one more time but in the
# echo-mode to clean up the resulting expression.
echo "${result}," | ./beta-reducer.sed
