---
layout: home
title: baluchicken.github.io/aptrepo
---


### Add a Debian Repository

Download the public key and put it in
`/etc/apt/keyrings/baluchicken-public.gpg`. You can achieve this with:

```
wget -qO- {{ site.url }}/baluchicken-public.asc | sudo tee /etc/apt/keyrings/baluchicken-public.asc >/dev/null
```

Next, create the source in `/etc/apt/sources.list.d/`

```
echo "deb [arch=all signed-by=/etc/apt/keyrings/baluchicken-public.asc] {{ site.url }}/deb stable main" | sudo tee /etc/apt/sources.list.d/baluchicken-public.list >/dev/null
```

Then run `apt update && apt install -y` and the names of the packages you want to install.