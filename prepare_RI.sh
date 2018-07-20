#!/bin/bash

# PS4=':$LINENO+'
# set -x

#check tempfile
if ! which tempfile 2> /dev/null >&2
then
    tempfile ()
    {
	mktemp
    }
fi

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
    sed -i 's|_QCD|_0|g;s|FOT|F|' Makefile
}

ORI_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

. $ORI_PATH/lib.sh

. pars_make.sh

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
add_list FOT
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

	#fft list
	for p in $(sed 's|QCD|0|;s|FOT|F|' prop_out.txt)
	do
	    echo "S_M${im}_R${r}_"$p
	done >&8
	
    done
done 8> fft_list.txt

rm ref_Makefile

mv $makefile_glb Makefile

#meson list
for((im1=0;im1<$nm;im1++))
do
    for((r1=0;r1<$nr;r1++))
    do
	A=M${im1}_R${r1}
	
	for((im2=0;im2<$nm;im2++))
	do
	    for((r2=0;r2<$nr;r2++))
	    do
		B=M${im2}_R${r2}
		
		echo "${A}_0_${B}_0               S_${A}_0         S_${B}_0"
		echo "${A}_F_${B}_F               S_${A}_F         S_${B}_F "
		echo "${A}_0_${B}_QED             S_${A}_0         S_${B}_QED"
	    done
	done

    done
done > mes_list.txt

prepara_input ()
{
    cat <<PREPARE
L $L
T $T
WallTime 60

Seed $SEED
StochSource 0
NHits 1

NSources 1
Name	 Tins	Store
ORI_SOURCE 	 0	0

TwistedRun 1

CloverRun 0

NProps $((4+$(grep LINCOMB Makefile|wc -l)))

Name		Ins	SourceName	Tins	Kappa		Mass	R	Charge	Theta	Residue	Store
PREPARE
    
    cat Makefile
    
    cat<<HALF

/* ///////////////////////////////////////////////////////////////// */

S_Msea_R0_0	-	LINCOMB 1
		ORI_SOURCE 1.0
					-1	$KSEA	$MSEA	0	0	0.0	1e-14	0
/* ///////////////////////////////////////////////////////////////// */

S_Msea_R1_0	-	LINCOMB 1
		ORI_SOURCE 1.0
					-1	$KSEA	$MSEA	1	0	0.0	1e-14	0

 ZeroModeSubtraction UNNO_ALEMANNA

 PhotonGauge LANDAU
 PhotonDiscretization WILSON

FreeTheory 0
RandomGaugeTransform 0

 LandauGaugeFix 1
 Gauge Landau
 TargetPrecision 5e-21
 NMaxIterations 100000
 UnitarizeEach 100
 Method Exponentiate
 AlphaExp 0.16
 UseAdaptativeSearch 1
 UseGeneralizedCg 1
 UseFFTacc 1
 StoreConf 0
LocHadrCurr 0
LocMuonCurr 0
NMes2PtsContr $((4+$(cat mes_list.txt|wc -l)))
HALF

    cat mes_list.txt

    cat<<MES
Msea_R0_0_Msea_R0_0     S_Msea_R0_0       S_Msea_R0_0
Msea_R0_0_Msea_R1_0     S_Msea_R0_0       S_Msea_R1_0
Msea_R1_0_Msea_R0_0     S_Msea_R1_0       S_Msea_R0_0
Msea_R1_0_Msea_R1_0     S_Msea_R1_0       S_Msea_R1_0
MES

    cat <<CONTR
NGammaContr 2

V0P5
P5P5

NMesLepQ1Q2LepmassMesMass 0

NBar2PtsContr 0

NHandcuffsContr 0

NFftProps $(cat fft_list.txt|wc -l)
CONTR
    
    cat fft_list.txt
    
    cat <<FINAL

NFftRanges 3

L 0 1
T 0 1

P4FrP22Max 2.00

L 1 2
T 1 2

P4FrP22Max 2.00

L 0 ${fft_max_L}
T 0 ${fft_max_T}

P4FrP22Max 0.29


ApeSmearingAlpha 0
ApeSmearingNiters 0

FINAL
}

prepara_input > input_hadr_new
