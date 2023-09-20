#!/usr/bin/env python3
#
import subprocess

baseSize = "1G"
destinationPath = "/Volumes/restricted/Test"

def performance_test(s):
    d = subprocess.run(["/usr/bin/dd", "if=/dev/zero", "of=" + s + "/test.img", "bs=" + baseSize, "count=1"], stderr=subprocess.PIPE)
    d = d.stdout
    print(d)
    # s = d.decode('utf-8')
    # l = s.split("\n")
    # print(l)

# startTime = time.time()
performance_test(destinationPath)
# endTime = time.time()