#!/bin/bash

. lib.sh

nm=1
nr=1
im=0
r=0
kappa=0.125
m=(0.0)
deltam_cr=(0.0)
deltam_tm=(0.0)
im_r=$(($r+$nr*$im))

rm -fr list_*.txt
list_assolved_up_to=0
next_new_list=0

add_list RI_QED
add_list QED
add_list RI
add_list PH
add_list QCD

assolve_lists

prepare_graph > graph.txt
dot -Tpng > "graph.png" < graph.txt

makefile=$(tempfile)
prepare_makefile > $makefile
mv $makefile Makefile

makefile=$(tempfile)
reorder_dependency > $makefile
mv $makefile Makefile

makefile=$(tempfile)
cat Makefile|mapfile -C decorate_line -c 1 arr > $makefile
mv $makefile Makefile
