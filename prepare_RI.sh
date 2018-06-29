#!/bin/bash

prepare_list_RI ()
{
 echo $1-H-E
}

prepare_list_PH ()
{
 echo $1-A-E
}

prepare_list_QCD ()
{
 echo $1-E
}

prepare_list_RI_QED ()
{
    for i in  '' A T S P H
    do
	for j in '' A T S P H
	do
	    for k in '' A T S P H
	    do
		str=$(echo "-$i-$j-$k-"|sed 's|---|-|g;s|--|-|g')
		
		p=1
		
		#remove repeated
		for s in A T S P H
		do
		    if [ $s == A ]
		    then
			need=2
		    else
			need=1
		    fi
		    
		    n=$(echo $str|grep $s -o|wc -l)
		    
		    if [ $n -ne $need ] && [ $n -ne 0 ]
		    then
			p=0
		    fi
		    
		done
		
		#remove higher order
		count=0
		for s in A T S P
		do
		    count=$(($count+$(echo $str|grep $s -o|uniq|wc -l)))
		done
		
		if [ $count -gt 1 ]
		then
		    p=0
		fi
		
		#suppress T with others
		if [ "$i" == T ] || [ "$j" == T ] || [ "$k" == T ]
		then
		    if [ "$i" == A ] || [ "$j" == A ] || [ "$k" == A ]
		    then
			p=0
		    fi
		fi
		
		if [ $p == 1 ]
		then
		    echo $1$str"E"
		fi
		
	    done
	done
    done|grep H|sort|uniq
}    

prepare_list_QED ()
{
    for i in  '' A T S P
    do
	for j in '' A T S P
	do
	    str=$(echo "-$i-$j-$k-"|sed 's|---|-|g;s|--|-|g')
	    p=1
	    
	    #remove repeated
	    for s in A T S P
	    do
		if [ $s == A ]
		then
		    need=2
		else
		    need=1
		fi
		
		n=$(echo $str|grep $s -o|wc -l)
		
		if [ $n -ne $need ] && [ $n -ne 0 ]
		then
		    p=0
		fi
		
	    done
	    
	    #remove higher order
	    count=0
	    for s in A T S P
	    do
		count=$(($count+$(echo $str|grep $s -o|uniq|wc -l)))
	    done
	    
	    if [ $count -gt 1 ]
	    then
		p=0
	    fi
	    
	    #suppress T with others
	    if [ "$i" == T ] || [ "$j" == T ] || [ "$k" == T ]
	    then
		if [ "$i" == A ] || [ "$j" == A ] || [ "$k" == A ]
		then
		    p=0
		fi
	    fi
	    
	    if [ $p == 1 ]
	    then
		echo $1$str"E"
	    fi
	    
	done
    done|awk '$1!=""'|sort|uniq
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

rm -fr list_*.txt
list_assolved_up_to=0
next_new_list=0

add_list ()
{
    label_sed[$next_new_list]=$1
    prepare_list_$1  >  ori_list_${1}.txt    $next_new_list
    prepare_new_list $1 $next_new_list ori_list_${1}.txt
}    

add_list RI_QED
add_list QED
add_list RI
add_list PH
add_list QCD

while [ $list_assolved_up_to -lt $next_new_list ]
do
    for i in A P S T H - E
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
	label=$(echo $ins|sed 's|-|prop|;s|H|vect|;s|P|pseudo|;s|T|tadpole|;s|A|photon|;s|S|scalar|;s|E|SOURCE|')
	
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
	    color=red
	fi
	
	#green for res
	if isnum $ins
	then
	    color=orange
	fi
		
	echo $i "[label = \"$label\", color=$color]"
	
	grep Need $f | awk '{print $10 " -> " '$i'}'
    done
    echo "}"
}

prepare_graph > graph.txt
dot -Tpng > "graph.png" < graph.txt
