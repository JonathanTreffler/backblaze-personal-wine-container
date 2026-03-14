#!/usr/bin/env python3
import re

file_path = '/wine-11.0/dlls/mountmgr.sys/device.c'

with open(file_path, 'r') as f:
    content = f.read()

replacement = '''case IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS:
    {
        VOLUME_DISK_EXTENTS info = {0};
        if (irp->MdlAddress && irp->MdlAddress->ByteCount >= sizeof(VOLUME_DISK_EXTENTS))
        {
            info.NumberOfDiskExtents = 1;
            info.Extents[0].DiskNumber = 0;
            info.Extents[0].StartingOffset.QuadPart = 0;
            info.Extents[0].ExtentLength.QuadPart = 0x10000000000; /* 1 TB */
            memcpy(irp->AssociatedIrp.SystemBuffer, &info, sizeof(VOLUME_DISK_EXTENTS));
            irp->IoStatus.Information = sizeof(VOLUME_DISK_EXTENTS);
            irp->IoStatus.Status = STATUS_SUCCESS;
        }
        else
        {
            irp->IoStatus.Status = STATUS_BUFFER_TOO_SMALL;
        }
    }
    break;'''

new_content, count = re.subn(r'case IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS:.*?(?=case IOCTL_STORAGE_QUERY_PROPERTY)', replacement, content, flags=re.DOTALL)
if count == 0:
    raise SystemExit('ERROR: could not find IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS handler to patch')

with open(file_path, 'w') as f:
    f.write(new_content)

print('Patched mountmgr.sys/device.c to return synthetic disk extents')
