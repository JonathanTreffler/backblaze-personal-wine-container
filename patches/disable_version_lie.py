#!/usr/bin/env python3

file_path = '/wine-11.0/dlls/kernelbase/version.c'

with open(file_path, 'r') as f:
    content = f.read()

content = content.replace('version->dwMajorVersion = 6;', 'version->dwMajorVersion = 10;')
content = content.replace('version->dwMinorVersion = 2;', 'version->dwMinorVersion = 0;')

with open(file_path, 'w') as f:
    f.write(content)

print('Patched kernelbase/version.c to disable version lie')
