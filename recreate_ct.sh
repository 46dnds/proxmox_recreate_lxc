#!/bin/bash

# default values
TEMPLATE="NFS-Freenas:vztmpl/ubuntu-16.04-standard_16.04-1_amd64.tar.gz"
ATTACH="0"

usage="usage: bash recreate_ct.sh -c 123 -a (to attach) -t (template)"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--template)
    TEMPLATE="$2"
    shift # past argument
    shift # past value
    ;;
    -c|--container)
    ct="$2"
    shift # past argument
    shift # past value
    ;;
    -a|--attach)
    ATTACH="1"
    shift # past argument
    shift # past value
    ;;
    -u|--usage)
    echo "$usage"
	exit
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ ! -f "/etc/pve/lxc/$ct.conf" ];then
    echo "Unknown CT. $usage"
    exit
fi
#STORAGES=""
#pvesm status | while read line
#do
#	stname=`echo $line | awk '{print $1}'`
#	ststatus=`echo $line | awk '{print $3}'`
#	if [ "$ststatus" = "active" ];then
#		STORAGES="$STORAGES $stname"
#	fi
#done

while read line
do
	cf_key=`echo $line | awk -F': ' '{print $1}'`
	cf_val=`echo $line | awk -F': ' '{print $2}'`

	if [ "$cf_key" = "arch" ]; then
		ctarch=$cf_val
	fi
	if [ "$cf_key" = "cores" ]; then
		ctcores=$cf_val
	fi
	if [ "$cf_key" = "hostname" ]; then
		cthostname=$cf_val
	fi
	if [ "$cf_key" = "memory" ]; then
		ctmemory=$cf_val
	fi
	if [ "$cf_key" = "nameserver" ]; then
		ctnameserver=$cf_val
	fi
	if [ "$cf_key" = "net0" ]; then
		ctnet0=$cf_val
	fi
	if [ "$cf_key" = "ostype" ]; then
		ctostype=$cf_val
	fi
	if [ "$cf_key" = "rootfs" ]; then
		ctrootfs=$cf_val
		#local-lvm:vm-115-disk-1,size=40G
		ctrootvol=`echo $ctrootfs | awk -F':' '{print $1}'`
		ctrootvolsize=`echo $ctrootfs | awk -F'size=' '{print $2}' | sed 's/[^0-9]*//g'`
	fi
	if [ "$cf_key" = "searchdomain" ]; then
		ctsearchdomain=$cf_val
	fi
	if [ "$cf_key" = "swap" ]; then
		ctswap=$cf_val
	fi
done < "/etc/pve/lxc/$ct.conf"

TYPE="";
while [ "$TYPE" = "" ]; do
	read -e -p "You are about to DESTROY ct #$ct ($cthostname). Are you sure?? type 'yes' to continue:" GOTTYPE
	case $GOTTYPE in
		[yes]* ) TYPE="yes"; break;;
		* ) TYPE="no";
	esac
done
if [ "$TYPE" = "no" ]; then
    echo "Aborted."
    exit 1
fi
echo "Processing..."
pct stop $ct
echo "pct destroy $ct"
pct destroy $ct
echo "pct create $ct $TEMPLATE --arch $ctarch --cores $ctcores --hostname $cthostname --memory $ctmemory --nameserver $ctnameserver --net0 $ctnet0 --ostype $ctostype --rootfs $ctrootvol:$ctrootvolsize --searchdomain $ctsearchdomain --swap $ctswap"
pct create $ct $TEMPLATE --arch $ctarch --cores $ctcores --hostname $cthostname --memory $ctmemory --nameserver $ctnameserver --net0 $ctnet0 --ostype $ctostype --rootfs $ctrootvol:$ctrootvolsize --searchdomain $ctsearchdomain --swap $ctswap
pct start $ct
echo "Done"
if [ "$ATTACH" = "1" ];then
	lxc-attach --name $ct
fi
