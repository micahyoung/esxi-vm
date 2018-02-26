#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source state/env.sh
: ${ESX_USERNAME:?"!"}
: ${ESX_PASSWORD:?"!"}
: ${ESX_HOST:?"!"}
: ${ESX_DATASTORE:?"!"}
: ${ESX_NETWORK:?"!"}
: ${VM_NAME:?"!"}
: ${VM_IP:?"!"}
: ${VM_GATEWAY:?"!"}
: ${VM_NETMASK:?"!"}
: ${VM_NAMESERVER:?"!"}
: ${VM_HOSTNAME:?"!"}
: ${VM_PASSWORD:?"!"}
: ${CPUS:?"!"}
: ${MEMORY_MB:?"!"}
: ${DISK_SIZE:?"!"}

mkdir -p bin
if ! [ -f bin/govc ]; then
  curl -L https://github.com/vmware/govmomi/releases/download/v0.15.0/govc_darwin_amd64.gz > bin/govc.gz
  gzip -d bin/govc.gz
  chmod +x bin/govc
fi

if ! [ -f bin/esx.iso ]; then
  echo "bin/esx.iso missing: Download and copy to the path"
  exit 1
fi

if ! [ -d bin/esx ]; then
  xorriso -osirrox on -indev bin/esx.iso -extract / bin/esx
fi

#if ! [ -f bin/esx-auto.iso ]; then
  cat > state/KS.CFG <<EOF
vmaccepteula
rootpw $VM_PASSWORD
install --firstdisk --overwritevmfs
network --bootproto=static --addvmportgroup=1 --device=vmnic0 --ip=$VM_IP --gateway=$VM_GATEWAY --hostname=$VM_HOSTNAME --nameserver=$VM_NAMESERVER --netmask=$VM_NETMASK --vlanid=3
reboot
EOF
  
  cat > state/BOOT.CFG <<EOF
bootstate=0
title=Loading ESXi installer
timeout=5
kernel=/tboot.b00
kernelopt=runweasel ks=cdrom:/KS.CFG
modules=/b.b00 --- /jumpstrt.gz --- /useropts.gz --- /features.gz --- /k.b00 --- /chardevs.b00 --- /a.b00 --- /user.b00 --- /uc_intel.b00 --- /uc_amd.b00 --- /sb.v00 --- /s.v00 --- /ata_liba.v00 --- /ata_pata.v00 --- /ata_pata.v01 --- /ata_pata.v02 --- /ata_pata.v03 --- /ata_pata.v04 --- /ata_pata.v05 --- /ata_pata.v06 --- /ata_pata.v07 --- /block_cc.v00 --- /char_ran.v00 --- /ehci_ehc.v00 --- /elxnet.v00 --- /hid_hid.v00 --- /i40en.v00 --- /igbn.v00 --- /ima_qla4.v00 --- /ipmi_ipm.v00 --- /ipmi_ipm.v01 --- /ipmi_ipm.v02 --- /ixgben.v00 --- /lpfc.v00 --- /lsi_mr3.v00 --- /lsi_msgp.v00 --- /lsi_msgp.v01 --- /misc_cni.v00 --- /misc_dri.v00 --- /mtip32xx.v00 --- /ne1000.v00 --- /nenic.v00 --- /net_bnx2.v00 --- /net_bnx2.v01 --- /net_cdc_.v00 --- /net_cnic.v00 --- /net_e100.v00 --- /net_e100.v01 --- /net_enic.v00 --- /net_fcoe.v00 --- /net_forc.v00 --- /net_igb.v00 --- /net_ixgb.v00 --- /net_libf.v00 --- /net_mlx4.v00 --- /net_mlx4.v01 --- /net_nx_n.v00 --- /net_tg3.v00 --- /net_usbn.v00 --- /net_vmxn.v00 --- /nhpsa.v00 --- /nmlx4_co.v00 --- /nmlx4_en.v00 --- /nmlx4_rd.v00 --- /nmlx5_co.v00 --- /ntg3.v00 --- /nvme.v00 --- /nvmxnet3.v00 --- /ohci_usb.v00 --- /pvscsi.v00 --- /qedentv.v00 --- /qfle3.v00 --- /qflge.v00 --- /qlnative.v00 --- /sata_ahc.v00 --- /sata_ata.v00 --- /sata_sat.v00 --- /sata_sat.v01 --- /sata_sat.v02 --- /sata_sat.v03 --- /sata_sat.v04 --- /scsi_aac.v00 --- /scsi_adp.v00 --- /scsi_aic.v00 --- /scsi_bnx.v00 --- /scsi_bnx.v01 --- /scsi_fni.v00 --- /scsi_hps.v00 --- /scsi_ips.v00 --- /scsi_isc.v00 --- /scsi_lib.v00 --- /scsi_meg.v00 --- /scsi_meg.v01 --- /scsi_meg.v02 --- /scsi_mpt.v00 --- /scsi_mpt.v01 --- /scsi_mpt.v02 --- /scsi_qla.v00 --- /shim_isc.v00 --- /shim_isc.v01 --- /shim_lib.v00 --- /shim_lib.v01 --- /shim_lib.v02 --- /shim_lib.v03 --- /shim_lib.v04 --- /shim_lib.v05 --- /shim_vmk.v00 --- /shim_vmk.v01 --- /shim_vmk.v02 --- /uhci_usb.v00 --- /usb_stor.v00 --- /usbcore_.v00 --- /vmkata.v00 --- /vmkplexe.v00 --- /vmkusb.v00 --- /vmw_ahci.v00 --- /xhci_xhc.v00 --- /emulex_e.v00 --- /btldr.t00 --- /weaselin.t00 --- /esx_dvfi.v00 --- /esx_ui.v00 --- /lsu_hp_h.v00 --- /lsu_lsi_.v00 --- /lsu_lsi_.v01 --- /lsu_lsi_.v02 --- /lsu_lsi_.v03 --- /native_m.v00 --- /rste.v00 --- /vmware_e.v00 --- /vsan.v00 --- /vsanheal.v00 --- /vsanmgmt.v00 --- /tools.t00 --- /xorg.v00 --- /imgdb.tgz --- /imgpayld.tgz
build=
updated=0
EOF
  
  xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -eltorito-boot ISOLINUX.BIN \
    -eltorito-catalog BOOT.CAT \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -output bin/esx-auto.iso \
    bin/esx \
    state/BOOT.CFG \
    state/KS.CFG \
  ;
#fi

export GOVC_INSECURE=1
export GOVC_URL=$ESX_HOST
export GOVC_USERNAME=$ESX_USERNAME
export GOVC_PASSWORD=$ESX_PASSWORD
export GOVC_DATASTORE=$ESX_DATASTORE
export GOVC_NETWORK=$ESX_NETWORK
#export GOVC_RESOURCE_POOL='*/Resources'

if ! bin/govc datastore.ls esx-auto.iso >/dev/null; then
  bin/govc datastore.upload bin/esx-auto.iso esx-auto.iso
fi

bin/govc vm.create \
  -c=$CPUS \
  -m=$MEMORY_MB \
  -disk=$DISK_SIZE \
  -ds=datastore1 \
  -iso=esx-auto.iso \
  -net.adapter=vmxnet3 \
  -on=false \
  $VM_NAME \
;

bin/govc vm.change -vm $VM_NAME -nested-hv-enabled=true

bin/govc vm.power -on=true $VM_NAME