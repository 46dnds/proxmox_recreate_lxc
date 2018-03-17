# proxmox_recreate_lxc

with our cloud provider we have a really useful feature: rebuild from a template (they call it an image) so we can, from the interface, recreate the container from the original state but keeping all the settings (name, ip, dns, etc)

we thought that feature was missing from proxmox so we created a script to do this. (cli only for now)

usage:

bash recreate_ct.sh -c 100 -a -t local:vztmpl/ubuntu-16.04-standard_16.04-1_amd64.tar.gz

# what this is doing:
-c recreate container #100

the script will parse config file, stop original container, destroy it, create with same specs

-a attach container after so you have a shell

-t use specified template (in this case ubuntu server 16.04)
