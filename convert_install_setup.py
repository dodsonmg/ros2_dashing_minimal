#!/usr/bin/python3

import os

try:
    LD_LIBRARY_PATH =os.environ['LD_LIBRARY_PATH']
except:
    LD_LIBRARY_PATH = ""

if(LD_LIBRARY_PATH == ""):
    print('LD_LIBRARY_PATH is not set')
    exit(0)

LD_LIBRARY_PATHs = LD_LIBRARY_PATH.split(':')

LD_CHERI_LIBRARY_PATH = "."
for path in LD_LIBRARY_PATHs:
    print(path)
    LD_CHERI_LIBRARY_PATH += ":" + path

with open('cheri_install_setup.txt', 'w') as fout:
    fout.write("setenv LD_CHERI_LIBRARY_PATH " + LD_CHERI_LIBRARY_PATH + "\n\n")
    fout.write("setenv LD_LIBRARY_PATH " + LD_CHERI_LIBRARY_PATH)
