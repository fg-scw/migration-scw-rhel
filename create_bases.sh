#!/usr/bin/env sh

set -eu  # quitte sur erreur ou variable non définie

echo "➤ Installation des paquets virt-v2v et python3-libguestfs…"
sudo dnf -y install virt-v2v python3-libguestfs unzip

BASE_DIR="bases"

mkdir -p \
  "$BASE_DIR/etc/NetworkManager/conf.d" \
  "$BASE_DIR/etc/sysconfig" \
  "$BASE_DIR/etc/systemd/system/qemu-guest-agent.service.d" \
  "$BASE_DIR/root/.ssh"

cat > "$BASE_DIR/etc/NetworkManager/conf.d/00-scaleway.conf" <<'EOF'
[connection]
# The value 0 stands for eui64 -- see nm-settings-nmcli(5)
ipv6.addr-gen-mode=0
EOF

cat > "$BASE_DIR/etc/sysconfig/qemu-ga.scaleway" <<'EOF'
# This file is brought by the Scaleway OS image
FILTER_RPC_ARGS="--allow-rpcs=guest-file-close,guest-file-open,guest-file-write,guest-ping"
EOF

cat > "$BASE_DIR/etc/systemd/system/qemu-guest-agent.service.d/50-scaleway.conf" <<'EOF'
# This file is brought by the Scaleway OS image
[Service]
EnvironmentFile=/etc/sysconfig/qemu-ga.scaleway
EOF

cat > "$BASE_DIR/root/.ssh/instance_keys" <<'EOF'
# Here you can put your custom ssh keys
# They will be concatenated to '/root/.ssh/authorized_keys'
EOF

cat > "$BASE_DIR/root/.s3cfg.sample" <<'EOF'
[default]
default_mime_type = binary/octet-stream
delete_removed = False
dry_run = False
enable_multipart = True
encoding = UTF-8
encrypt = False
follow_symlinks = False
force = False
get_continue = False
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase =
guess_mime_type = True
host_base = s3.%(location)s.scw.cloud
host_bucket = %(bucket)s.s3.%(location)s.scw.cloud
human_readable_sizes = False
invalidate_on_cf = False
list_md5 = False
log_target_prefix =
mime_type =
multipart_chunk_size_mb = 250
preserve_attrs = True
progress_meter = True
recursive = False
recv_chunk = 256000
reduced_redundancy = False
send_chunk = 256000
signature_v2 = False
skip_existing = False
socket_timeout = 300
urlencoding_mode = normal
use_https = True
verbosity = WARNING
website_endpoint = https://%(bucket)s.s3.%(location)s.scw.cloud/
website_error =
website_index = index.html
check_ssl_certificate = True
check_ssl_hostname = True

access_key = INSERT_ORGANIZATION_ID
secret_key = INSERT_PRIVATE_TOKEN
bucket_location = INSERT_S3_REGION
location = INSERT_S3_REGION
EOF

chmod 700 "$BASE_DIR/root/.ssh"
chmod 600 "$BASE_DIR/root/.ssh/instance_keys"

echo "Arborescence créée dans \`$BASE_DIR/\`"
