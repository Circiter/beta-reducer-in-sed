#!/bin/sh

verbose=0
filename=""
iterations_limit=1000
iterations=0

for i in $@; do
    if [ "$i" = "--verbose" ]; then
        verbose=1
    else
        filename="$i"
    fi
done

if [ "x$filename" = x ]; then
    echo 'Usage: ./full-reduction.sh [--verbose] <program_filename>'
    echo '       echo <expression> | ./full-reduction.sh [--verbose] -'
    exit
fi

if [ "$filename" = "-" ]; then
    expression="`cat`"
else
    expression="`cat $filename`"
fi

# Preprocess.
expression="`echo "$expression" | ./preprocessor.sed`"

# Reduce.
while true; do
    [ $verbose = 1 ] && echo "$expression"
    result="`echo "$expression" |  ./beta-reducer.sed`"
    iterations=$(( $iterations + 1 ))
    [ $iterations -ge $iterations_limit -o "x$result" = "x$expression" ] && break
    expression="$result"
done

# Run the beta-reduce.sed one more time but in the
# echo-mode to clean up the resulting expression.
expression="`echo "${result}," | ./beta-reducer.sed`"

[ $verbose = 1 -a "x$expression" != "x$result" -o $verbose = 0 ] && echo $expression
