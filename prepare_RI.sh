#!/bin/bash

#PS4=':$LINENO+'
#set -x

fullfill ()
{
    local makefile=$(tempfile)
    cat ref_Makefile|mapfile -C decorate_line -c 1 arr > $makefile
    mv $makefile Makefile
    
    for i in $(cat prop_out.txt)
    do
	sed -i 's/\(^\|\ \|\t\)'$i'/S_M'$im'_R'$r'_'$i'/' Makefile
    done
    
    for i in $(seq 0 $list_assolved_up_to)
    do
	sed -i 's/\(^\|\ \|\t\)_'$i'/S_M'$im'_R'$r'_'$i'/' Makefile
    done
    
    #QCD -> 0
    sed -i 's|QCD|0|g' Makefile
}

. lib.sh

. pars.sh

rm -fr list_*.txt prop_out.txt
list_assolved_up_to=0
next_new_list=0

# add_list RI_QED
# add_list RI_QED 0
# add_list RI_QED 1
# add_list RI_QED 2
# add_list RI_QED 3
add_list QED
#add_list RI
add_list F
add_list QCD

assolve_lists

prepare_graph > graph.txt
dot -Tpng > "graph.png" < graph.txt

#prepare the makefile
makefile=$(tempfile)
prepare_makefile > $makefile
mv $makefile ref_Makefile

#reorder the dependency
makefile=$(tempfile)
reorder_dependency ref_Makefile> $makefile
mv $makefile ref_Makefile

makefile_glb=$(tempfile)
for((im=0;im<$nm;im++))
do
    for((r=0;r<$nr;r++))
    do
	im_r=$(($r+$nr*$im))
    
	fullfill
	cat Makefile >> $makefile_glb
#	cp Makefile Makefile_${im}_${r}
    done
done

rm ref_Makefile

mv $makefile_glb Makefile
