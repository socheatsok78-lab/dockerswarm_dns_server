## Deployment

> WIP

On some systems specially **Debian** based, port `53` is used by `systemd-resolved` and will need to be disabled. See [Troubleshooting](#troubleshooting) for more information on how to disable `systemd-resolved`.

## Troublshooting

### Disable `systemd-resolved`

As root, edit the `/etc/systemd/resolved.conf`` with your text editor of choice.

```sh
sudo nano /etc/systemd/resolved.conf
```

Now, you'll want to uncomment (remove the #) the DNS= and DNSStubListener= lines.

You'll now want to change the `DNS=` value to your DNS server of choice and then change the value of the `DNSStubListener=` from `yes` to `no`

```ini
DNS=8.8.8.8
DNSStubListener=no
```

Now, save your changes and exit the editor.

Next, you'll want to create a symbolic link for `/run/systemd/resolve/resolv.conf` with `/etc/resolv.conf` as the destination.

```sh
# Backup etc/resolv.conf.bak
sudo mv /etc/resolv.conf /etc/resolv.conf.bak

# Create new symlink from /run/systemd/resolve/resolv.conf to /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Reboot or restart `systemd-resolved.service`
reboot # or
sudo systemctl restart systemd-resolved.service
```

You'll note the `-s`, which makes the link symbolic instead of a hard link and the `-f` is to remove any existing destination files.

Now, you should be able to reboot your system and be able to use port `53`.

You can check this by running the following command:

```sh
sudo lsof -i :53
```

If you see no output, then port 53 should be open.

### Re-enable `systemd-resolved`

To undo this you'll edit the `/etc/systemd/resolved.conf` and put the settings back to the way it originally was.

Add the `#` back in front of the `DNS=` line and change the `DNSStubListener=` back to `no`.

Then you can remove that symbolic link by typing the following:

```sh
sudo rm /etc/resolv.conf
```

Then reboot.
