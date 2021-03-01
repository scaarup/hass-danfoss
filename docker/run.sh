docker run \
--name danfoss-decode \
--restart always \
--privileged -v /dev/bus/usb:/dev/bus/usb \
-d -v $(pwd):/entrypoint scaa/danfoss-decode
