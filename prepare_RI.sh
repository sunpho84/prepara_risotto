#!/bin/bash

. lib.sh

# rm -fr list_*.txt
# list_assolved_up_to=0
# next_new_list=0

# add_list RI_QED
# add_list QED
# add_list RI
# add_list PH
# add_list QCD

# assolve_lists

# prepare_graph > graph.txt
# dot -Tpng > "graph.png" < graph.txt

# prepare_makefile > temp_Makefile

for i in $(awk '{print $1}' temp_Makefile)
do
    get_dep_reco $i
done

#rm -fr temp_Makefile
