#!/bin/bash
# generate a version/build string to be included in the initramfs

echo \
	`git describe --tags --always --dirty` \
	`hostname` \
	`date '+%F %T'`
