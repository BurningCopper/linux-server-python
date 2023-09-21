#!/usr/bin/env python3
#
import subprocess

baseSize = "1G"
# destinationPath = "/Volumes/restricted/Test"
destinationPath = "."

def performance_test(s):
    d = subprocess.run(["/usr/bin/dd", "if=/dev/zero", "of=" + s + "/test.img", "bs=" + baseSize, "count=1"], stderr=subprocess.PIPE)
    d = d.stderr
    s = d.decode('utf-8')
    s = s.rstrip("\n")
    l = s.split("\n")
    s = l[-1]
    return s

# Main program begins
print("Speed test results for " + destinationPath + ":")

for i in range(5):
    write_speed = performance_test(destinationPath)
    write_speed_list = write_speed.split(",")
    write_speed = write_speed_list[-1]
    print(write_speed)