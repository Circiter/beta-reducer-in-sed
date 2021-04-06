#!/bin/sed -Enf

# (C) By Circiter (mailto:xcirciter@gmail.com).
# License: MIT.

:read $!{N; bread}

/\n$/! s/$/\n/

:remove_comment s/--[^\n]*\n/\n/; tremove_comment

# FIXME: What about a recursive definitions?
:process_definition
    s/^[\n\t ]*([^\n\t ])/\1/

    /^[_a-zA-Z]* *= *[^\n]*\n/! {
        s/\$//g; s/([^ \n])[ \n]*$/\1/
        p; q
    }

    s/^[^\n]*\n/&$/
    :replace
        s/^([_a-zA-Z]*) *= *([^\n]*)(\n.*[^_a-zA-Z])\1([^_a-zA-Z])/\1=\2\3\2\4/
        /^([_a-zA-Z]*) *= *[^\n]*\n.*[^_a-zA-Z]\1[^_a-zA-Z]/ breplace

    s/^[^\n]*\n\$//

    bprocess_definition
