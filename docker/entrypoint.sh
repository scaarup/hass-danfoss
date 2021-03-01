#!/bin/bash
rtl_sdr -f 868420000 -s 2000000 -g 10  - | /waving-z/build/wave-in -u | /entrypoint/decode.sh
#rtl_sdr -f 868420000 -s 2000000 -g 25  - | /waving-z/build/wave-in -u
