#!/usr/bin/bash
set -euo pipefail

export LIBGUESTFS_BACKEND=direct

SOURCE_QCOW="$1"
DEST="$2"

V2VED_BASENAME=$(basename "$SOURCE_QCOW" .qcow2)
V2VED_QCOW="V2VED-${V2VED_BASENAME}"

BUILD_DIR="$(mktemp -d /var/tmp/v2v-build.XXXXXX)"
BACKUP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$BUILD_DIR" "$BACKUP_DIR"; }
trap cleanup EXIT
chmod a+rx "$BUILD_DIR"

LIBGUESTFS_BACKEND=direct virt-v2v \
  -i disk "$SOURCE_QCOW" \
  -o qemu \
  -on "$V2VED_QCOW" \
  -os "$BUILD_DIR" \
  -of qcow2 \
  -oc qcow2

QCOW_OUT="$BUILD_DIR/${V2VED_QCOW}-sda"
chmod 666 "$QCOW_OUT" || true
chcon --type virt_image_t "$QCOW_OUT" 2>/dev/null || true

virt-copy-out -a "$QCOW_OUT" /etc/passwd /etc/shadow /etc/group /etc/gshadow "$BACKUP_DIR"

python3 migrate_centos.py "$QCOW_OUT"

virt-copy-in -a "$QCOW_OUT" "$BACKUP_DIR/passwd"  /etc
virt-copy-in -a "$QCOW_OUT" "$BACKUP_DIR/shadow"  /etc
virt-copy-in -a "$QCOW_OUT" "$BACKUP_DIR/group"   /etc
virt-copy-in -a "$QCOW_OUT" "$BACKUP_DIR/gshadow" /etc

virt-customize -a "$QCOW_OUT" \
  --run-command "mkdir -p /etc/ssh/sshd_config.d" \
  --run-command "bash -c 'printf \"PermitRootLogin yes\nPasswordAuthentication yes\n\" > /etc/ssh/sshd_config.d/99-rootpw.conf'" \
  --selinux-relabel

mv "$QCOW_OUT" "$DEST"
