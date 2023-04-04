#!/bin/bash -e

# Copyright 2022-present Orange
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to install virtual machine.

if [ -e "$WORKING_DISK_IMAGE" ]; then
  echo "VM already exist - second invocation of $0, so exiting with an error"
  exit 1
fi

# Create storage for docker image(s) in VM
qemu-img create -f qcow2 "$DOCKER_VOLUME_IMAGE" 12G
virt-format --format=qcow2 --filesystem=ext4 -a "$DOCKER_VOLUME_IMAGE"

# Copy boot images for every kernel
mkdir -p /mnt/inner /tmp/vm
guestmount -a "$DISK_IMAGE" -i --ro /mnt/inner/
cp "/mnt/inner/boot/initrd.img-$KERNEL_VERSION-generic" /tmp/vm/
cp "/mnt/inner/boot/vmlinuz-$KERNEL_VERSION-generic" /tmp/vm/
guestunmount /mnt/inner

# Make working copy of disk image
cp "$DISK_IMAGE" "$WORKING_DISK_IMAGE"

# Move docker test image into VM, require to boot VM
./tools/ci-ptf/run_test.sh "$KERNEL_VERSION" docker load -i "$P4C_IMAGE"
rm -f "$P4C_IMAGE"
