# Migration d’une appliance OVA vers KVM/QEMU

> **Objectif** : convertir une image distribuée au format **OVA/OVF** (souvent issue de VMware/VirtualBox) en une image **QCOW2** compatible avec **KVM/QEMU** et l’hyperviseur **libvirt**.

---

## 1. Prérequis

| Élément              | Rôle                                     | Exemple de paquet                                                               |
| -------------------- | ---------------------------------------- | ------------------------------------------------------------------------------- |
| Système hôte         | Hôte d’exécution de l’image résultat     | **RHEL 9, CentOS Stream 9, AlmaLinux 9**…                                       |
| Outils de conversion | Extraction de l’OVA et conversion disque | `libguestfs-tools-c` (contient `virt-v2v`, `virt-customize`, `virt-inspector`…) |
| Outils QEMU          | Manipulation des images QCOW2            | `qemu-img`, `qemu-kvm`, `virt-install`                                          |
| Espace disque        | Stockage temporaire & destination        | Prévoir **2 ×** la taille de l’OVA                                              |

Avant de commencer, activez le backend « direct » de libguestfs :

```bash
export LIBGUESTFS_BACKEND=direct
```

---

## 2. Conversion OVA → QCOW2

```bash
virt-v2v \
  -i ova povrhel9_scaleway_fabien.ova \
  -o local                   # sortie locale
  -os /root/toulouse/         # répertoire de destination
  -of qcow2                   # format final
  -oc qcow2                   # préallocation QCOW2
```

* **-i ova** : indique que la source est une archive OVA.
* **-o local** / **-os** : export local, vers `/root/toulouse/`.
* **-of/-oc qcow2** : force la sortie au format **QCOW2** (sparse par défaut).

Le disque principal est écrit sous le nom `povrhel9_scaleway-sda.qcow2` (ou similaire).

---

## 3. Renommage (optionnel)

Pour simplifier la suite :

```bash
cp /root/toulouse/povrhel9_scaleway-sda.qcow2 \
   /root/toulouse/povrhel9_scaleway_fabien.qcow2
```

---

## 4. Post‑traitement CentOS/RHEL

Si la VM était initialement prévue pour un hyperviseur VMware/VirtualBox, il est préférable de :

* basculer le contrôleur disque sur **virtio‑blk** ou **virtio‑scsi** ;
* injecter les pilotes virtio dans l’image ;
* regénérer les labels SELinux, l’initramfs et l’`fstab` si nécessaire.

Le script maison `migrate_centos.sh` encapsule ces opérations :

```bash
./migrate_centos.sh \
  /root/toulouse/povrhel9_scaleway_fabien.qcow2 \
  /root/toulouse/povrhel9_scaleway_fabien_scriptOK.qcow2
```

> **Astuce** : ouvrez le script avant exécution pour adapter le chemin `guestfs` ou tout correctif spécifique à votre distribution.

---

## 5. Import libvirt

```bash
virt-install \
  --name povrhel9_scaleway_fabien \
  --memory 4096 --vcpus 2 \
  --disk path=/root/toulouse/povrhel9_scaleway_fabien_scriptOK.qcow2,format=qcow2,cache=none \
  --os-variant rhel9.0 \
  --network network=default,model=virtio \
  --import
```

* **--import** évite la création automatique d’un disque.
* Ajustez **mémoire**, **CPU**, **réseau** selon votre besoin.

---

## 6. Vérifications après démarrage

1. **Dmesg/Journalctl** : absence d’erreurs virtio, SELinux ou initramfs.
2. **Interfaces réseau** : nouvelle MAC address et adaptateur virtio actif.
3. **chkconfig/systemctl** : services critiques lancés.
4. **yum/dnf update** : mise à jour des paquets & kernel.

---

## 7. Nettoyage & sauvegarde

* Supprimez l’archive **OVA** si l’image QCOW2 est validée.
* Conservez un **snapshot** (ou une copie) de l’image avant mise en production.
* Automatisez la procédure avec **Ansible** ou un **Pipeline CI** pour les migrations répétitives.

---

### Ressources utiles

* [Documentation virt‑v2v](https://libguestfs.org/virt-v2v.1.html)
* [Guide virt‑install](https://virt-manager.org/) (virt‑manager)
* [QEMU QCOW2 format](https://wiki.qemu.org/Documentation/Storage)
