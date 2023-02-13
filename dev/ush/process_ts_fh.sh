#/bin/bash

EXEC=/nwprod/wave_code.v4.15.1/st4c/exec

YYYY=2017

rm 00/* 24/* 48/* 120/*

for MM in 06 07
do

for DD in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
do

for cyc in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23
do


for bname in 45001 45004 45006 45023 45025 45027 45028 45136 45002 45007 45022 45024 45026 45029 45161 45170 45003 45008 45137 45143 45149 45154 45012 45135 45139 45159 45160 45005 45132 45142 45147 45165
do
fdirname=glwu.${YYYY}${MM}${DD}.t${cyc}z/glwu.${bname}.ts
    sed '4!d' $fdirname >> ./00/grlc_2p5km.${bname}.ts
    sed '28!d' $fdirname >> ./24/grlc_2p5km.${bname}.ts
    sed '52!d' $fdirname >> ./48/grlc_2p5km.${bname}.ts
    sed '124!d' $fdirname >> ./120/grlc_2p5km.${bname}.ts
done
done
done
done


