# Migration d’une appliance OVA vers Instance SCW

> **Objectif** : convertir une image distribuée au format **OVA/OVF** (issue de VMware) en une image **QCOW2** compatible avec **Scaleway Instance**

---

## 1. Script de déploiement Arborescence & Dépendances 
```bash
./create_bases.sh
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

Le script `migrate_centos.sh` encapsule ces opérations :

```bash
./migrate_centos.sh \
  /root/toulouse/povrhel9_scaleway_fabien.qcow2 \
  /root/toulouse/povrhel9_scaleway_fabien_scriptOK.qcow2
```
---
