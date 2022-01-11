#!/bin/bash
#
echo ${PDK_ROOT:=/usr/share/pdk} > /dev/null

if [ ! -f caravel.spice ]; then
magic -dnull -noconsole -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc << EOF
drc off
crashbackups stop
load caravel
select top cell
expand
extract do local
extract all
ext2spice lvs
ext2spice
EOF
rm -f *.ext
fi

export NETGEN_COLUMNS=60
export MAGIC_EXT_USE_GDS=1
netgen -batch lvs "caravel.spice digital_pll" "../verilog/gl/digital_pll.v digital_pll" $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl comp.out
