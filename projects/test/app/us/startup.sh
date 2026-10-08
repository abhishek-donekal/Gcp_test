#!/bin/bash
# Runs on every boot (delivered via metadata, so edits apply without a rebuild).
# Formats the workspace disk on first boot and mounts it at /opt/workspace.
set -euo pipefail

log() { echo "[startup] $*"; }

DEVICE=/dev/disk/by-id/google-workspace
MOUNT=/opt/workspace

# Wait up to 60s for the disk to show up.
for _ in $(seq 1 30); do
  [ -e "$DEVICE" ] && break
  sleep 2
done

if [ -e "$DEVICE" ]; then
  if ! blkid "$DEVICE" >/dev/null 2>&1; then
    log "formatting $DEVICE (first boot)"
    mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DEVICE"
  fi
  mkdir -p "$MOUNT"
  if ! grep -q " $MOUNT " /etc/fstab; then
    UUID=$(blkid -s UUID -o value "$DEVICE")
    echo "UUID=$UUID $MOUNT ext4 discard,defaults,nofail 0 2" >> /etc/fstab
  fi
  mountpoint -q "$MOUNT" || mount "$MOUNT"
  chmod 1777 "$MOUNT"
  log "workspace mounted at $MOUNT"
else
  log "WARNING: $DEVICE not found; skipping workspace mount"
fi

# Publish bucket locations for login shells.
MD=http://metadata.google.internal/computeMetadata/v1/instance/attributes
DATA_BUCKET=$(curl -sf -H 'Metadata-Flavor: Google' "$MD/data-bucket" || true)
STAGING_BUCKET=$(curl -sf -H 'Metadata-Flavor: Google' "$MD/staging-bucket" || true)
cat > /etc/profile.d/test-env.sh <<PROFILE
export DATA_BUCKET="$DATA_BUCKET"
export STAGING_BUCKET="$STAGING_BUCKET"
PROFILE
log "DATA_BUCKET=$DATA_BUCKET STAGING_BUCKET=$STAGING_BUCKET"
