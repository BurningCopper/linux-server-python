#!/usr/bin/env python3
#
import subprocess

baseSize = "10G"
destinationPath = "/Volumes/restricted/Test"

def performance_test(s):
    d = subprocess.run(["/usr/bin/dd", "if=/dev/zero", "of=" + s + "/test.img", "bs=10G", "count=1"], stdout=subprocess.PIPE)
    d = d.stdout
    s = d.decode('utf-8')
    print(s)

# startTime = time.time()
performance_test(destinationPath)
# endTime = time.time()