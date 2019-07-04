# warrion08_infra

## **Оглавление:**
- ### Локальное окружение инженера(#ДЗ №2)
- ### Знакомство с облачной инфраструктурой и облачными сервисами(#ДЗ №3)

<a name="ДЗ №2"></a>
#### Локальное окружение инженера. ChatOps и визуализация рабочих процессов. Командная работа с Git. Работа в GitHub.

##### Создание ветки репозитория:
```
- $ git clone git@github.com:otus-devops-2019-05/warrion08_infra.git
- $ cd warrion08_infra
- $ git branch play-travis
- $ git checkout play-travis
```
##### Добавление шаблона PR:
```
$ mkdir .github
$ cd .github
$ wget http://bit.ly/otus-pr-template -O PULL_REQUEST_TEMPLATE.md
$ git add PULL_REQUEST_TEMPLATE.md
$ git commit -m 'Add PR template'
$ git push --set-upstream origin play-travis
```

##### Интеграция GitHub и Slack:
Для получения нотификаций в Slack об изменениях на GitHub долна быть настроена интеграция бота с пространством по инструкции.
Чтобы подписаться на нотификации, выполнить команду в Slack-канале:
`/github subscribe Otus-DevOps-2019-05/warrion08_infra commits:all`

##### Интеграция с Trevis CI:
Trevis CI - это бесплатный сервис непрерывной сборки и тестирования для проектов, размещенных на GitHub.
Добавление файла с тестом
```
$ mkdir play-travis
$ cd play-travis
$ wget https://raw.githubusercontent.com/express42/otus-snippets/master/hw-04/test.py
$ git add test.py
$ git commit -m "add test.py"
$ git push
```
##### Добавление инструкции для сборки:
Создаем в корне репозитория .yml файл,
`$ touch .travis.yml`
В котором описываем инструкции для сборки:
```dist: trusty
sudo: required
language: bash
before_install:
- curl https://raw.githubusercontent.com/express42/otus-homeworks/2019-05/run.sh |
bash
```

##### Шифрование токена Trevis CI и Slack интеграция
```
$ apt-get update
$ apt-get upgrade
$ apt-get install ruby-dev
$ gem install travis
```
##### Логинимся и добавляем шифрованный токен в .trevis.yml
```
$ travis login --com
$ travis encrypt "<trevis_slack_token>#aleksey_voynov" --add notifications.slack.rooms --com
```
В .trevis.yml добавились параметры для Slack интеграции
Тестирование билда и исправление python скрипта:
```
$ git status
$ git commit -m "add encrypted .travis.yml file"
$ git show
$ git push
```
Оповещение от Trevis приходит, но билд упал. Смотрим лог,проблема в функции test_equal() в test.py. Исправляем и коммитим. Билд успешно собран.

<a name="ДЗ №3"></a>
#### ДЗ №3: Знакомство с облачной инфраструктурой и облачными сервисами.

##### Адреса для подключения
```
bastion_IP = 35.210.13.7
someinternalhost_IP = 10.132.0.3
```

##### Инициализация GCP
```
Создаем новую учетную запись в Google Cloud Platform.
Создаем новый проект Infra.
Генерируем ssh-ключи и публичный ключ добавляем в метеданные проекта (по умолчанию действует на все VM в проекте)
`$ ssh-keygen -t rsa -f ~/.ssh/appuser -C appuser -P ""`
```

#### Создание инстанса VM c внешним IP (подключение через bastion host)

###### Создаем VM:
```
Name: bastion
Zone: europe-west1-d
Machine type: f1-micro (1 vCPU, 0.6 GB memory)
Boot disk: Ubuntu 16.04
Hostname: bastion
External IP: bastion (35.210.13.7)
```

###### Проверяем подключение

`$ ssh -i ~/.ssh/appuser.pub appuser@35.210.13.7`

##### Создание инстанса VM без внешнего IP

Создаем VM:
```
Name: someinternalhost
Zone: europe-west1-d
Machine type: f1-micro (1 vCPU, 0.6 GB memory)
Boot disk: Ubuntu 16.04
Hostname: someinternalhost
```
Для возможности подключения к someinternalhost из внутренней (от bastion), добавляем приватный ключ в агент авторизации на локальной машине

`$ ssh-add ~/.ssh/appuser`

Включаем SSH Agent Forwarding при помощи параметра -A, затем пробуем подключиться к someinternalhost
```
$ ssh -i ~/.ssh/appuser -A appuser@35.210.13.7
$ ssh 10.132.0.3
```

##### Подключение к someinternalhost с локальной машины одной командой

С добавлением параметра -J (использование jump host)

`$ ssh -i ~/.ssh/appuser.pub -J appuser@35.210.13.7 appuser@10.132.0.3`

С использованием директивы ProxyJump В файле ~/.ssh/config добавляем:
```
Host bastion
  User appuser
  Hostname 35.210.13.7
  ForwardAgent yes
  IdentityFile ~/.ssh/appuser.pub

Host someinternalhost
  User appuser
  Hostname 10.132.0.3
  ProxyJump bastion
  ```
Теперь подключение к someinternalhost может выглядеть следующий образом:

`$ ssh someinternalhost`

##### Добавляем алиас, для подключения в одно слово

`$ alias someinternalhost='ssh someinternalhost'`

#### Создание VPN сервера при помощи Pritunl
```
В настройках bastion инстанса в разделе Firewalls разрешаетм HTTP, HTTPS трафик. 
Появились теги http-server, https-server.
Выполняем команды для установки pritunl.
Создаем в web-интерфейсе pritunl организацию, пользователя, сервер. Привязываем сервер к организации и запускаем.
В настройках сети GCP добавляем правило в Firewall
Name: vpn-15871
Targets: vpn-15871
Filters: IP ranges: 0.0.0.0/0
Protocols / ports: udp:15871
Добавляем правило vpn-15871 в теги сети bastion сервера
Скачиваем конфигурационный файл *.ovpn в web интерфейсе Pritunl
Добавляем конфиг в клиент OpenVPN
 sudo openvpn --config ~/cloud-bastion.ovpn
Подключаемся к someinternalhost с локальной машины
ssh -i ~/.ssh/appuser appuser@10.132.0.3
```
