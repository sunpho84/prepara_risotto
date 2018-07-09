#!/bin/bash

get_e2_weight ()
{
    case $1 in
	S|T|P) echo 2;;
	F) echo  1;;
	''|V|W|X|Y|Z) echo  0;;
	*)
	    echo "Unknown pattern \"$1\"" >&2
	    exit
    esac	
}

get_V_weight ()
{
    case $1 in
	S|T|P|F|'') echo 0;;
	V|W|X|Y|Z) echo  1;;
	*)
	    echo "Unknown pattern \"$1\"" >&2
	    exit
    esac	
}

get_RI_ins ()
{
    if [ "$1" == "" ]
    then
	echo V
    else
	local ins=(W X Y Z)
	if [ "$1" -le 3 ] && [ "$1" -ge 0 ]
	then
	    echo ${ins[$1]}
	else
	    echo "$1 not in the range 0-3" >&2
	    exit
	fi
    fi
}

prepare_list_RI ()
{
    echo $1-$(get_RI_ins $2)-E
}

prepare_list_F ()
{
    echo $1-F-E
}

prepare_list_QCD ()
{
    echo $1-E
}

prepare_list_RI_QED ()
{
    for i in  '' F T S P $(get_RI_ins $2)
    do
	for j in '' F T S P $(get_RI_ins $2)
	do
	    for k in '' F T S P $(get_RI_ins $2)
	    do
		str=$(echo "-$i-$j-$k-"|sed 's|---|-|g;s|--|-|g')
		
		if [ $(($(get_e2_weight "$i") + $(get_e2_weight "$j") + $(get_e2_weight "$k"))) == 2 ] && [ $(($(get_V_weight "$i") + $(get_V_weight "$j") + $(get_V_weight "$k"))) == 1 ]
		then
		    echo $1$str"E"
		fi
		
	    done
	done
    done|sort|uniq
}    

prepare_list_QED ()
{
    for i in  '' F T S P
    do
	for j in '' F T S P
	do
	    str=$(echo "-$i-$j-"|sed 's|--|-|g')
	    
	    if [ $(($(get_e2_weight "$i") + $(get_e2_weight "$j"))) == 2 ]
	    then
		echo $1$str"E"
	    fi
	    
	done
    done|sort|uniq
}    

prepare_new_list ()
{
    {
	echo "# To obtain list $1 with insertion $2:"
	echo "# "
	grep -v \# $3|awk '{print "## "$0}'
	echo "#"
	echo "# Insert $2 on:"
	echo "#"
	
	awk '{print substr($1,2)}' $3 | sort | uniq
    } > list_$next_new_list.txt
    
    next_new_list=$(($next_new_list+1))
}

add_list ()
{
    if [ "$2" == "" ]
    then
	name=$1
    else
	name=$1\_$(get_RI_ins $2)
    fi
    label_sed[$next_new_list]=$name

    prepare_list_$1 $next_new_list $2 >  ori_list_${1}.txt 
    prepare_new_list $name $next_new_list ori_list_${1}.txt
    
    echo $name >> prop_out.txt
}    

assolve_lists ()
{
    while [ $list_assolved_up_to -lt $next_new_list ]
    do
	for i in F P S T V W X Y Z - E
	do
	    echo "Checking if needed to insert $i for list $list_assolved_up_to"
	    dependency=""
	    
	    grep ^$i list_$list_assolved_up_to.txt > working_list.txt
	    
	    #check that the list is not empty
	    if [ $(cat working_list.txt|wc -l) == 0 ]
	    then
		needed=0
	    else
		needed=1
		echo "Empty list"
	    fi
	    
	    #check that the list is not already computed
	    if [ $needed == 1 ]
	    then
		echo "Checking list with previous $next_new_list to verify if new needed"
		
		for l in $(seq 0 $(($next_new_list-1)))
		do
		    grep \#\# list_$l.txt|awk '{print $NF}'|diff - working_list.txt -y
		    if [ $? == 0 ]
		    then
			echo "List found on file $l"
			
			needed=0
			
			dependency=$l
		    fi
		    echo ---------------
		done
	    fi
	    
	    if [ $needed == 1 ]
	    then
		echo ""
		
		dependency=$next_new_list
		
		prepare_new_list $list_assolved_up_to $i working_list.txt ""
	    fi
	    
	    if [ "$dependency" != "" ]
	    then
		echo "# Need to get the insertion of $i from $dependency" >> list_$list_assolved_up_to.txt
	    fi
	done
	
	list_assolved_up_to=$(($list_assolved_up_to+1))
    done
}

isnum()
{
  printf "%f" $1 >/dev/null 2>&1
}

prepare_graph ()
{
    echo "digraph G {"
    # echo "0 [label=\"RESULT\"]"
    # echo "1 -> 0"
    
    for i in $(seq 0 $(($next_new_list-1)))
    do
	f=list_$i.txt

	ins=$(grep "# Insert" $f|awk '{print $3}')
	
	#label
	label=$(echo $ins|sed 's|-|prop|;s|V|vect|;s|W|vect_t|;s|X|vect_x|;s|Y|vect_y|;s|Z|vect_z|;s|P|pseudo|;s|T|tadpole|;s|F|photon|;s|S|scalar|;s|E|SOURCE|')
	
	#transform label for result
	for is in $(seq 0 $((${#label_sed[@]}-1)))
	do
	    label=$(echo $label|sed 's|'$is'|'${label_sed[$is]}'|')
	done

	###########################################
	
	#color
	color=black
	
	#red for prop
	if [ "$ins" == - ]
	then
	    color=firebrick1
	fi
	
	#green for res
	if isnum $ins
	then
	    color=forestgreen
	fi
		
	echo $i "[label = \"$label\", color=$color]"
	
	grep Need $f | awk '{print $10 " -> " '$i'}'
    done
    echo "}"
}

prepare_makefile ()
{
    local tempfile=$(tempfile)
    
    for i in $(seq 0 $(($next_new_list-1)))
    do
	f=list_$i.txt

	ins=$(grep "# Insert" $f|awk '{print $3}'|sed 's|W|V0|;s|X|V1|;s|Y|V2|;s|Z|V3|')
        
	sources=$(grep Need $f | awk '{print "_"$10}')

	skip=0
	
	#get result name if a number is found
	if isnum $ins
	then
	    skip=1
	    replace=$replace"s|$sources|${label_sed[$ins]}|g;"
	fi
	
	#get original source
	if [ "$ins" == "E" ]
	then
	    skip=1
	    replace=$replace"s|_$i|ORI_SOURCE|g;"
	fi

	if [ $skip != 1 ]
	then
	    echo $1_$i $ins $sources
	fi
    done > $tempfile

    sed "$replace" $tempfile

    rm $tempfile
}

get_dep_reco () #pass the name
{
    a=($(awk '$1=="'$1'"{print NR,$0}' ref_Makefile))
    if [ ${#a[@]} == 0 ] && [ "$1" != "ORI_SOURCE" ]
    then
	echo "Unable to find line $1"
	exit
    fi

    local iline=${a[0]}
    local name=${a[1]}
    local ins=${a[2]}
    local dep=${a[@]:3}
    
    echo $trailer"Found $name on line $iline, ins $ins, deps: $dep" >&2
    
    if [ "${assolved[$iline]}" != 1 ]
    then

	#mark as done
	assolved[$iline]=1
	
     	for i in $dep
	do
	    if [ $i != "ORI_SOURCE" ]
	    then
		#prepend a .
		trailer=".$trailer"
		
		get_dep_reco $i
	    fi
	done
		
    	#print the computation
	echo -e $name\\t$ins\\t$dep

	#munge the .
	trailer=$(echo $trailer|sed 's|^.||')
	
    else
	echo $trailer"Dep $i was assolved" >&2
    fi
}

reorder_dependency ()
{
    unset assolved
    
    for i in $(awk '{print $1}' $1)
    do
	get_dep_reco $i
    done
}

decorate_line ()
{
    data=($@)
    out=${data[1]}
    ins=${data[2]}
    echo -e "$out\\t\\t$ins\\tLINCOMB\\t$((${#data[@]}-3))"
    
    for sou in ${data[@]:3}
    do
     	prev_ins=$(grep ^$sou Makefile|awk '{print $2}')

	case $prev_ins in
	    P)
		tau3=(-1 +1)
		coef=$(echo "${tau3[$r]} ${deltam_cr[$im_r]}"|awk '{print $1*$2}')
		weight="(0.0,$coef)";;
	    S)
		weight=$(echo "-(${deltam_tm[$im_r]})"|bc -l);;
	    *) weight="1.0";;
	esac
       	
     	echo -e "\\t\\t\\t$sou $weight"
    done

    charge=0.0
    theta=0.0
    residue=1e-14
    store=0
    
    if [ $ins == "-" ]
    then
	echo -e "\\t\\t\\t\\t\\t-1\\t$(printf %.6f $kappa)\\t${m[$im]}\\t$r\\t$charge\\t$theta\\t$residue\\t$store"
    else
	echo -e "\\t\\t\\t\\t\\t-1\\t\\t\\t$r\\t$charge\\t\\t\\t$store"
    fi
    echo "/* ///////////////////////////////////////////////////////////////// */"
}
