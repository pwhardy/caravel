#!/bin/bassh
#
echo ${PDK_ROOT:=/usr/share/pdk} > /dev/null

if [ ! -f caravan.spice ]; then
magic -dnull -noconsole -rcfile $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc << EOF
drc off
crashbackups stop
load caravan
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
netgen -batch lvs "caravan.spice caravan" "../verilog/gl/caravan.v caravan" $PDK_ROOT/$PDK/libs.tech/netgen/$PDK_VARIENT_setup.tcl comp.out
