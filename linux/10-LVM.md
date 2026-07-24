# Logical Volume Management

## Concepts
- PV - Physical Volume
- VG - Volume Group
- LV - Logical Volume

## Example
```bash
sudo pvcreate /dev/sdb
sudo vgcreate data-vg /dev/sdb
sudo lvcreate -L 20G -n data-lv data-vg
```

## Extend
```bash
sudo lvextend -r -L +10G /dev/data-vg/data-lv
```

## Best Practice
Monitor free space in volume groups and plan filesystem growth before applications run out of storage.
