#!/bin/sed -Enf

# Beta reducer (for the pure untyped lambda calculus).

# In fact, it's an interpreter of a small programming language --- the lambda calculus
# (save the fact that it currently only support one step of the beta-reduction).

# Usage: echo '<lambda_expression>' | ./beta_reducer.sed

# (C) By Circiter (mailto:xcirciter@gmail.com).
# Permanent storage: https://github.com/Circiter/beta-reducer-in-sed
# License: MIT.

# BNF grammar:
#
# abstraction ::= \variable.abstraction
#                 application
# application ::= application unary
#                 unary
# unary ::= variable
#           ( abstraction )
#           abstraction # FIXME.
#
# variable ::= identifier
#              identifier < number >

# Abstraction is right-associative, e.g.: (\x\y M) = (\x(\y M)).
# Application is left-associative, e.g.: (L M N) = ((L M) N).
# Precedence of application is higher than that of abstraction,
# e.g.: (\x M N) = (\x (M N)).
# Outermost parentheses are optional.

# Angle brackets are used to specify the de Bruijn index of a
# variable. It's convenient to use one-based unary numbers as
# indices, allowing the usage of empty angle brackets to denote
# a free variable.

# TODO: Add support for custom definitions (like "true = \x\y x").

# TODO: Complete the "parenthesis minification" logic; e.g. the
# expression "(\x x) y" now reduces to (y<>), which contains an
# extra pair of parenthesis. Note, however, that just another
# execution of the beta-reducer will clean up such an expression.

# Beta-reduction: (\x A) y -> A[x=y]

# This script uses the call by name reduction strategy,
# at every step choosing the leftmost outermost redex
# but never reducing inside abstractions.

:read $!{N; bread}

# Convert all the whitespace characters into ordinary spaces.
y/\n\t/  /

s/$/$/ # Add a sentinel.

x
s/$/\nkind=;\n/
s/$/begin_components\n1\nend_components\n/ # Stack of components.
s/$/begin_to_close\nend_to_close\n/ # Stack of closing parenthesis insertions.
s/$/begin_variables\nend_variables\n/ # Stack of variables.
x

s/$/\n/; babstraction # Entry rule is abstraction.

# If a de Bruijn indices are present then use them instead
# of string identifiers.

# abstraction ::= \variable.abstraction
#                 application
# Abstraction is right-associative, e.g.: (\x\y M) = (\x(\y M)).
:abstraction
    s/^ *([^ ])/\1/; # Remove whitespace.

    /^\\/ {
        x
        s/$/ \\/
        s/begin_variables\n/&@/; s/$/---/; G

        s/@(.*)---\n\\([a-z_]*)[^a-z_]/\2@\n\1\2 ---/ # Push the variable name.

        # The space right after the \ says that variable references are given as
        # de Bruijn indices.
        s/\n@/\n.@/ # The . in the stack means that the addressing done through de Bruijn's indexing.

        s/---.*$//
        x

        s/^\\[a-z_]*([^a-z_])/\1/; s/^\\ // # Remove "\variable".

        x
        # Mark leftmost outermost abstraction.
        /\[/! {s/@/=/; s/$/\[ /;}
        s/@//
        x

        s/$/\nreturn101/; babstraction; :return101 # Recursive call.

        # Mark the end of [the body of] the marked abstraction.
        # FIXME: Consider to replace the ; by the ].
        # Current abstraction is selected/marked if the TOS is equal
        # to the marked variable.
        x
        # Current abstraction is marked if the TOS is marked.
        /begin_variables\n[^\n]*=\n/ s/$/;/
        x

        x; s/(begin_variables\n)[^\n]*\n/\1/; x # Pop variable.

        x; s/(\nkind=)[^;]*;/\1lambda;/; x

        bend_abstraction
    }

    s/$/\nreturn102/; bapplication; :return102

    :end_abstraction

    /return101$/ {s/\n[^\n]*$//; breturn101}
    /return103$/ {s/\n[^\n]*$//; breturn103}
    /return105$/ {s/\n[^\n]*$//; breturn105}
    bend

# Pattern match application(abstraction(x, e), y) and substitute x=y in e.

# FIXME: What is the meaning of empty subexpressions like ()?

# application ::= application unary
#                 unary
# Application is left-associative, e.g.: (L M N) = ((L M) N).
# Precedence of application is higher than that of abstraction,
# e.g.: (\x M N) = (\x (M N)).
:application
    s/^ *([^ ])/\1/; # Remove whitespace.

    x; s/$/ (/
    s/begin_to_close\n/&0\n/ # ToClose=false.
    x

    s/$/\nreturn8/; bunary; :return8

    x
    /\nkind=lambda;/! {
        x
        s/$/\nreturn201/
        bfixup_bracket
        :return201
        bnoclose
    }
    s/(begin_to_close\n).\n/\11\n/ # ToClose=true.
    x
    :noclose

    x; s/begin_components\n/&1/; x

    # Use the ; marker left after the abstraction body to determine
    # that the lhs is a marked abstraction.
    :while3
        s/^ *([^ ])/\1/
        /^ *\$/ bend_application
        /^ *\)/ bend_application

        x
        # If ToClose=true then s/$/)/ and ToClose=false
        /begin_to_close\n1\n/ {
            s/$/ )/
            s/(begin_to_close\n)1\n/\10\n/
        }

        # Select the rhs of application if the lhs is the marked lambda.
        # Then, if the rhs is not already selected, then select it.
        /;[ \),]*$/ {/end_argument/! {s/$/ begin_argument /; s/^/level:\n/}}
        # Increment the level.
        s/level:/&1/
        s/$/( /
        x

        s/$/\nreturn10/; bunary; :return10

        x
        /\nkind=id;/ {
            x
            s/$/\nreturn202/
            bfixup_bracket
            :return202
            bnoemitclose
        }
        s/$/ )/
        x
        :noemitclose

        x; s/$/ /

        s/begin_components\n/&1/

        # The processing must be done on the same recursive level
        # as the matching begin_argument insertion.
        /level:1\n/ {/begin_argument/ {/end_argument/! s/$/ end_argument /}}
        s/(level:)1/\1/ # Decrement the level.
        s/level:\n//
        x

        bwhile3
    :end_application

    # If application contains at least two components, then...
    x; /begin_components\n11/ s/(\nkind=)[^;]*;/\1app;/

    /begin_to_close\n1\n/ {
        x; s/$/\nreturn203/; bfixup_bracket; :return203; x
    }
    s/(begin_to_close\n).\n/\1/ # Remove the variable ToClose from the stack.
    x

    /return102$/ {s/\n[^\n]*$//; breturn102}
    bend

# Search a variables by its de Bruijn index, if any.

# unary ::= variable
#           ( abstraction )
:unary
    s/^ *([^ ])/\1/; # Remove whitespace.

    /^\(/ { # Parse "(abstraction)".
        s/^\( *//
        x; s/begin_components/&\n/; x
        s/$/\nreturn103/; babstraction; :return103
        s/ *\) *//

        x
        s/$/ /
        s/(begin_components\n)[^\n]*\n/\1/
        x

        bend_unary
    }

    /^[<a-z_]/ { # Variable reference (identifier with or without de Bruijn index).
        x
        s/$/ @/; G
        /begin_variables\n\.=.*@\n([a-z_])*[^<a-z_]/ {
            s/\.=/=/
            i Error: A de Bruijn index expected but only an identifier is given.
        }
        s/@\n([a-z_]*)[^<a-z_].*$/\1!1!/ # Insert a new de Bruijn index.
        s/^(.*)@\n([a-z_]*)(<1*>).*$/\3\1\2\3/ # Save the de Bruijn index.

        # Search the variable name in the variables stack.
        s/begin_variables\n/&@/ # Select TOS.
        :search
            /@end_variables/ {
                s/!1*!$/!!/ # Not found.
                bend_search
            }

            # Compare (by the string identifier).

            /@([^\n]*)\n.*\1!1*!$/ bend_search # Found and unmarked.

            /@([^=\n]*)=.*\1!1*!$/ { # Found and marked.
                s/ ([a-z_]*)(!1*!)$/ \1*\2/ # Mark this term as well.
                bend_search
            }

            # NB, de Bruijn index has higher priority; for if an identifier
            # is provided then use it (ignoring a de Bruijn index, if any).
            # After the first beta-reduction the identifiers may be wrong so
            # it's better to use a de Bruijn indices by default.

            # Compare by the de Bruijn index.

            /^<1>.*@[^\n]*\n$/ bend_search # Found and unmarked.
            /^<1>.*@[^=\n]*=/ { # Found and marked.
                s/ ([a-z_]*)(<1*>)$/ \1*\2/
                bend_search
            }

            s/^<11/<1/ #s/^<(1*)1>/<\1>/ # Decrement the value of the saved index.
            s/!(1*)!$/!\11!/ # Increment the de Bruijn index.
            s/@([^\n]*\n)/\1@/ # Select next item.
            bsearch
        :end_search
        s/!(1*)!$/<\1>/
        s/^<1*>//
        s/@//
        x

        s/^[a-z_]*([^a-z_])/\1/; s/^<1*>//

        x; s/(\nkind=)[^;]*;/\1id;/; x
        
        bend_unary
    }

    s/$/\nreturn105/; babstraction; :return105

    :end_unary
    /return8$/ {s/\n[^\n]*$//; breturn8}
    /return10$/ {s/\n[^\n]*$//; breturn10}
    bend

:end
s/^.*$//
x

# Remove all the content except the lambda-expression itself.
s/^.*\n([^\n]*)$/\1/

# Perform substitution.

# Replace all the marked variables (<var_name>*) by the
# argument between "begin_argument" and "end_argument",
# then remove the argument.
:substitute
    s/ [a-z_]*\*<1*>(.* begin_argument)(.*)( end_argument)/ \2\1\2\3/ # FIXME.
    / [a-z_]*\*/ bsubstitute

s/ begin_argument.* end_argument// # Remove the [actual] argument.

# Extract the body of the marked lambda abstraction.
s/ \\ *[a-z_]* *\[(.*);/\1/

# Remove excessive spaces.
s/^[ \n]*([^ \n])/\1/; s/([^ ]) *$/\1/
:space
    s/\( /(/; tspace; s/ \)/)/; tspace
    s/  / /; tspace

p; q

:fixup_bracket
    x
    # Scan the working buffer from the end to
    # the beginning and remove one rightmost
    # unbalanced open parenthesis.
    s/^/1\n/ # Insert a counter.
    s/$/@/
    :search_bracket
        /\)@/ s/^/1/ # Increment the counter.
        /\(@/ s/^1// # Decrement the counter.
        /^\n/ {s/.@/ /; bfound;}  # Unbalanced parenthesis found.
        s/([^\n])@/@\1/
        /[^\n]@/ bsearch_bracket
    :found
    s/^1*\n//; s/@//
    x

    /return201$/ {s/\n[^\n]*$//; breturn201}
    /return202$/ {s/\n[^\n]*$//; breturn202}
    /return203$/ {s/\n[^\n]*$//; breturn203}
    i fixup_bracket -> terra incognita
    bend
