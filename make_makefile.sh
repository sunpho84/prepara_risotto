#!/bin/bash

get_dep()
{
    grep "\->" graph.txt |awk '$3=='$1'{print $1}'
}


get_dep_reco()
{
    if [ "${assolved[$1]}" != 1 ]
    then
	local dep=($(get_dep $1))
	#echo "Resolving dependency of $1: ${dep[@]}"
	
	for i in ${dep[@]}
	do
	    get_dep_reco $i
	done

	ins=$(grep label graph.txt |awk '$1=='$1'{print $4}'|sed 's|,||')
	
	if [ ${#dep[@]} -gt 0 ]
	then
	    echo "$1 = $ins on ${dep[@]}"
	fi
	
	assolved[$1]=1
    # else
    # 	echo "$1 already assolved"
    fi
}

for((ires=0;ires<5;ires++))
do
    get_dep_reco $ires
done
