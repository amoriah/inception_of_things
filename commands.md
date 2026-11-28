### Part 1

```bash
vagrant up 
```
 ```bash
vagrant status
 ```
```bash
vagrant ssh <machine name>
```
```bash
k get nodes -o wide
```
interface_name - ip a
ip a show <interface name> - показывает IP-адреса и параметры только сетевого интерфейса eth1


### Part 2

на ветке наташа мак

curl -H "Host:app2.com" 192.168.56.110

### Part 3

    # Инструменты и кластер на защите запускаем вручную (см. README):
    #   vagrant ssh -c "bash /vagrant/scripts/install-tools.sh"
    #   vagrant ssh -c "bash /vagrant/scripts/bootstrap.sh"

