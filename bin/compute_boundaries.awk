#!/usr/bin/awk -f

# takes as input a gff files and a field number fldno in this file where the features for which we want
# to compute the boundaries from the gff features are, and compute the most5' and the most3' boundary
# of it, toadd is the name of the feature in fldnoth field
# the input file does not need to be sorted
# modified on April 27th 2021 so that it can add info from the 9th field about the feature with $fldno as id
# ideally we should not have to specify fldno it should be guessed looking from toadd"_id" in the 9th field

# usage
# cd ~/fragencode/workspace/sdjebali/geneswitch/pipelines/rnaseq/novel.annotation/add.gene.rows
# pgm=~/fragencode/tools/multi/Scripts/compute_boundaries.awk
# new=/work2/project/fragencode/workspace/cguyomar/tagada_results/rnaseq/capra_hircus/TAGADA.0.3.0lnc.ARS1.102.2021-04-06/assembly/assembly.gff
# time awk -v toadd=gene -v fldno=10 -v keys=gene_name,ref_gene_id -f $pgm $new > assembly.genes.gff
# real	0m9.124s

# input
# 1	StringTie	transcript	342921	372158	1000	+	.	gene_id "MSTRG.3"; transcript_id "ENSCHIT00000026177"; gene_name "CRYZL1"; ref_gene_id "ENSCHIG00000017812"; transcript_biotype "protein_coding";
# 1	StringTie	transcript	342927	369750	1000	+	.	gene_id "MSTRG.3"; transcript_id "ENSCHIT00000026192"; gene_name "CRYZL1"; ref_gene_id "ENSCHIG00000017812"; transcript_biotype "protein_coding";
# 1	StringTie	transcript	369751	380562	1000	+	.	gene_id "MSTRG.3"; transcript_id "ENSCHIT00000030576"; gene_name "DONSON"; ref_gene_id "ENSCHIG00000020590"; transcript_biotype "protein_coding";

# output
# 7	ensembl	gene	100011173	100030915	.	-	.	gene_id "ENSCHIG00000013130"; ref_gene_id "ENSCHIG00000013130";
# 2	StringTie	gene	101341067	101341177	.	-	.	gene_id "MSTRG.10013"; gene_name "5S_rRNA"; ref_gene_id "ENSCHIG00000005165";
# 15232 (10 fields)
# 8843 (12 fields)
# 4582 (14 fields)

# keys is a variable provided in the command line

BEGIN{
    OFS="\t";
    if(keys!="") {
        n=split(keys,key,","); # just get as many keys as provided by the user
        j=1;
        while(key[j]!="") {
            ok[key[j]]=1;
            j++;
        }
    }
}

$1!~/#/{                                    # avoid comments
    split($0,a,"\t"); # a is just the array name
    seen[$fldno]++; # keep how many times you get the feature (in a given field number) for instance gene_name

    # first time it appears keep the values we need
    if(seen[$fldno]==1) {

        chr[$fldno]=a[1];
        strand[$fldno]=a[7];
        cat[$fldno]=a[2]; ## category StringTie or ensembl
        fstbeg[$fldno]=a[4];
        lstend[$fldno]=a[5];

        if(keys!="") {
            split(a[9],b,"; "); # split field number 9 by ";"
            i=1;
            while(b[i]!="") {
                split(b[i],c," "); # split by " " each individual of the fields separated by ";"

                if(ok[c[1]]==1) { # if its one of the selected keys in the begin closure then add it to keep it
                    infotoadd[$fldno,c[1]]=c[2];
                }

                i++;
            }
	    }
    }
    else{
	    if(a[7]!=strand[$fldno]){
	        strand[$fldno]="."; ## if strand differs set .
	    }
        if(a[2]!=cat[$fldno]){
            cat[$fldno]="."; ## if category (StringTie, ensembl,...) differs set .
            }
        if(a[4]<fstbeg[$fldno]){
            fstbeg[$fldno]=a[4]; ## if begin is smaller set
        }
        if(a[5]>lstend[$fldno]){
            lstend[$fldno]=a[5]; ## if end is bigger set
        }
        if(keys!=""){
            split(a[9],b,"; "); ## split field number 9 by "; "
            i=1;
            while(b[i]!=""){
                split(b[i],c," "); ## split by " " each individual of the fields separated by "; "


                if(ok[c[1]]==1){ ## if its one of the selected keys in the begin closure then add it to keep it
                    ## if the value is different to the one set in the first appearance
                    ## then keep it in pb
                    if(c[2]!=infotoadd[$fldno,c[1]]){
                        pb[$fldno,c[1]]=1;
                    }
                }
                i++;
            }
        }
    }
}

END{
  for(k in seen){
        if(keys!=""){
            toadd2[k]=" ";
            for(i=1; i<=n; i++){
                if(pb[k,key[i]]!=1&&infotoadd[k,key[i]]!=""){
                    toadd2[k]=(toadd2[k])((key[i])" "(infotoadd[k,key[i]]))("; ");
                }
            }
        }
        gsub(/;;/,";",toadd2[k]);
        print chr[k], cat[k], toadd, fstbeg[k], lstend[k], ".", strand[k], ".", toadd"_id "(k)(toadd2[k]);
                              # toadd is the variable provided in the cmd line  # here is like a for for the dictionary
    }
}
