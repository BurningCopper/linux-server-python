#!/bin/bash

find /Volumes/Multisite/NIH_upload -type f -exec chmod 660 -- {} +
find /Volumes/Multisite/NIH_upload -type d -exec chmod 770 -- {} +

find /Volumes/Multisite/VMC_upload -type f -exec chmod 660 -- {} +
find /Volumes/Multisite/VMC_upload -type d -exec chmod 770 -- {} +

find /Volumes/Multisite/UWM_upload -type f -exec chmod 660 -- {} +
find /Volumes/Multisite/UWM_upload -type d -exec chmod 770 -- {} +

find /Volumes/Multisite/MMI_upload -type f -exec chmod 660 -- {} +
find /Volumes/Multisite/MMI_upload -type d -exec chmod 770 -- {} +

exit 0