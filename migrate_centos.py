#!/usr/bin/env python3
import logging
import sys
from pathlib import Path

import guestfs

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s:%(name)s:%(message)s")

BASES_DIR = Path(__file__).resolve().parent / "bases"

ACTIONS = [
    ["copy_in", str(BASES_DIR), "/run"],
    ["sh", "chown -R 0:0 /run/bases"],
    ["cp_a", "/run/bases/root", "/"],
    ["cp_a", "/run/bases/etc", "/"],
    ["chmod", 448, "/root"],
    ["chmod", 448, "/root/.ssh"],
    ["chmod", 420, "/etc/sysconfig/qemu-ga.scaleway"],
    ["chmod", 420, "/etc/systemd/system/qemu-guest-agent.service.d/50-scaleway.conf"],
    ["chmod", 420, "/etc/NetworkManager/conf.d/00-scaleway.conf"],
    ["chmod", 436, "/root/.ssh/instance_keys"],
    ["chmod", 493, "/etc"],
    ["chmod", 493, "/etc/sysconfig"],
    ["chmod", 493, "/etc/systemd"],
    ["chmod", 493, "/etc/systemd/system"],
    ["chmod", 493, "/etc/systemd/system/qemu-guest-agent.service.d"],
    ["chmod", 493, "/etc/NetworkManager"],
    ["chmod", 493, "/etc/NetworkManager/conf.d"],
    ["sh", 'echo "timeout 5;" > /etc/dhcp/dhclient.conf'],
    ["sh", "rm -Rf /run/bases"],
    ["sh", "rm -f /etc/ld.so.cache"],
    ["sh", ": > /etc/machine-id"],
    ["sh", "grubby --args=console=ttyS0,115200n8 --update-kernel $(grubby --default-kernel)"],
    ["sh", "systemctl set-default multi-user.target"],
    ["sh", r"sed -ri '/^net.ipv4.conf.all.arp_ignore\s*=/{s/.*/net.ipv4.conf.all.arp_ignore = 1/}' /etc/sysctl.conf"],
    ["umount", "/boot/efi"],
    ["selinux_relabel", "/etc/selinux/targeted/contexts/files/file_contexts", "/boot"],
    ["selinux_relabel", "/etc/selinux/targeted/contexts/files/file_contexts", "/"],
]

def guest_mount(g: guestfs.GuestFS) -> None:
    roots = g.inspect_os()
    if len(roots) != 1:
        raise RuntimeError(f"Impossible de gérer plusieurs racines : {roots}")
    root = roots[0]
    for mountpoint, device in sorted(g.inspect_get_mountpoints(root).items()):
        g.mount(device, mountpoint)

def main(qcow_path: str, debug: bool = False) -> None:
    g = guestfs.GuestFS(python_return_dict=True)
    g.backend = "direct"
    g.set_trace(debug)
    g.set_verbose(debug)
    logger.info("Ajout du disque : %s", qcow_path)
    g.add_drive_opts(qcow_path, format="qcow2", readonly=False)
    g.set_network(True)
    g.launch()
    guest_mount(g)
    for action in ACTIONS:
        mname, *args = action
        if not isinstance(mname, str):
            raise TypeError(f"Entrée mal formée dans ACTIONS : {action!r}")
        ret = getattr(g, mname)(*args)
        if isinstance(ret, int) and ret != 0:
            raise RuntimeError(f"{mname} a renvoyé le code d’erreur {ret}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(f"Usage : {sys.argv[0]} <image.qcow2>")
    main(sys.argv[1])
