

## Ssh "no mutual signature algorithm"

When connecting to older system with the `-vvvv` flag on you may noticed a failure to connect with public key with the error message `no mutual signature algorithm`. In 2021 openssh removed support for rsa. Older systems may still require this ([discussion](https://confluence.atlassian.com/bitbucketserverkb/ssh-rsa-key-rejected-with-message-no-mutual-signature-algorithm-1026057701.html
)). To resolve add the following as an option when connecting:

``ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa root@IP``

## Mounting fails due to SD card corruption
Symptoms:
- failing to mount SD system
- Every time connect SD card to read in workstation it shows up in DMESG with ro

Backup: Mount image with -o ro,noload

## ext4 bad geometry: block count 7851776 exceeds size of device (7806976 blocks)

fsck /dev/sdc2
resize2fs /dev/sdc2