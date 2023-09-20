#!/usr/bin/env python3
#
import subprocess

baseSize = "10G"
destinationPath = "/Volumes/restricted"

def performance_test(s):
    dd_subprocess = subprocess.run(["/usr/bin/dd", "if=/dev/zero", "of=" + s + "/test.img", "bs=10G", "count=1"], stdout=subprocess.PIPE)
    print(dd_subprocess) 

# startTime = time.time()
performance_test(destinationPath)
# endTime = time.time()