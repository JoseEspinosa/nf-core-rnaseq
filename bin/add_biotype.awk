#!/usr/bin/awk -f

BEGIN {
        FS = "\t"
}
NR == FNR {
    match($9, /transcript_id "([^;]*)";*/, tId)
    match($9, /transcript_biotype "([^;]*)";*/, biotype)
    biotypes[tId[1]] = biotype[1]
    next
}
{
    if (substr($1,1,1) != "#" && $3 != "gene") {
        match($9, /transcript_id "([^;]*)";*/, tId)
        if (tId[1] in biotypes) {
            print $0 " transcript_biotype \""biotypes[tId[1]]"\";"
        } else {
            print $0
        }
    } else {
        print $0
    }
}
