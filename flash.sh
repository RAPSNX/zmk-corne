#!/usr/bin/env bash

firmware="$HOME/Downloads/firmware.zip"
count=0

if [[ ! -f "$firmware" ]]; then
  echo "Missing firmware: $firmware" >&2
  exit 1
fi

cd "$HOME/Downloads" || exit 1

while true; do
  device="$(lsblk -rno LABEL,NAME | awk '$1 == "NICENANO" { print $2; exit }')"

  if [[ -n "$device" ]]; then
    if [[ $count -eq 0 ]]; then
      echo "Flash left side"

      unzip -o "$firmware"

      udisksctl mount -b "/dev/$device" >/dev/null 2>&1
      mountpoint="$(lsblk -rno MOUNTPOINT "/dev/$device")"

      cp -- corne_left*.uf2 "$mountpoint/"
      sync

      while [[ -n "$(lsblk -rno LABEL,NAME | awk '$1 == "NICENANO" { print $2; exit }')" ]]; do
        echo "Waiting for device to disconnect..."
        sleep 1
      done

      ((count++))
      continue
    fi

    if [[ $count -eq 1 ]]; then
      echo "Flash right side"

      udisksctl mount -b "/dev/$device" >/dev/null 2>&1
      mountpoint="$(lsblk -rno MOUNTPOINT "/dev/$device")"

      cp -- corne_right*.uf2 "$mountpoint/"
      sync

      echo "Done"
      rm -- "$firmware"
      exit 0
    fi
  else
    echo "Connect bootloader, waiting for half $count"
    sleep 2
  fi
done
