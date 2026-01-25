# VMDockerManagement
Create Ubuntu VMs with Docker. You can use it to share hardware resources while keeping software infrastructure separate including credentials. 

To use it run:
```
./create_vm.sh -n name -p password
```

Access VMs with ssh by:
```
ssh root@ipaddress -p port
```

It is a good idea to create your own username by `adduser` and then add yourself to sudoers by `sudo usermod -aG sudo <username>`

## Features
- Automatically assigns a different ssh port to each VM
- Creates a persistent data folder and mounts it to VM as `/data`
- Enables GPU use in the VMs
- Creates a cronjob to check if GPU is accessible, otherwise restarts the VM
- Testes with NVIDIA Spark
