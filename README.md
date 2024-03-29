
# warrion08_infra

## **Оглавление:**
- ### Локальное окружение инженера(#ДЗ №2)
- ### Знакомство с облачной инфраструктурой и облачными сервисами(#ДЗ №3)
- ### Основные сервисы GCP(#ДЗ №4)
- ### Сборка образов VM при помощи Packer(#ДЗ №5)
- ### Практика IaC с использованием Terraform(#ДЗ №6)
- ### Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform(#ДЗ №7)
- ### Управление конфигурацией. Основные DevOps инструменты. Знакомство с Ansible.(ДЗ №8)
- ### Деплой и управление кофигурацией с Ansible (ДЗ №9)
- ### Ansible: Работа с ролями и окружениями (ДЗ №10)
- ### Разработка и тестирование Ansible ролей и плейбуков (ДЗ №11)

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
#### Основные сервисы Google Cloud Platform (GCP)(#ДЗ №4)

```
testapp_IP = 34.77.190.149
testapp_port = 9292
```

##### Установили gcloud на локальной машине:
```
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get install apt-transport-https ca-certificates
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install google-cloud-sdk
```

##### Создали VM:
```
 gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure
  
  ```
  
##### Получили:
```
reddit-app  europe-west1-d  g1-small  10.132.0.5   34.77.190.149

```
##### Подключились к VM:
```
ssh appuser@34.77.190.149
```

##### Написали скрипты: 

install_ruby.sh
```
#!/bin/bash
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential
```

install_mongodb.sh
```
#!/bin/bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```
deploy.sh
```
#!/bin/bash
cd ~/home/appuser
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```
startup_script.sh
```
#!/bin/bash

#install mongo
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y mongodb-org && sudo systemctl start mongod && sudo systemctl enable mongod

#install ruby
sudo apt install -y ruby-full ruby-bundler build-essential

#deploy
cd ~/
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install && puma -d
echo 'Script is Finished'
```
##### Сделать скрипты исполняемыми
```
git update-index --chmod=+x file.sh

```

##### Для решения доп задания был создал инстанс следующей командой:
```
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup.sh
```
##### Создания правила брандмауэра из консоли gloud:
```
gcloud compute firewall-rules create default-puma-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server
```

#### Сборка образов VM при помощи Packer(#ДЗ №5)
> Установливаем packer и ADC по инструкции.
> Cоздаем новую ветку packer-base. 
> Создаем директорию packer с файлом ubuntu16.json
> В файле ubuntu16.json есть переменные которые определенны в variables.json

```
ssh_username
project_id
zone
source_image_family

```
Проверка на ошибки созданного файла:

`packer validate ./ubuntu16.json`

Подключаются при сборке командой:
`packer build -var-file=variables.json ubuntu16.json` 
На выходе получаем rebbit-base образ c mongo и rubby


*
Создамим сreate-reddit-vm.sh
Расположен в config-scripts/ С помощью gcloud создаем instance на основе шаблона --image-family reddit-full 
```
#!/bin/bash

#create instance
gcloud compute instances create reddit-base\
  --boot-disk-size=10GB \
  --image-family reddit-full \
  --machine-type=f1-micro \
  --tags reddit-full \
  --restart-on-failure \
  --zone europe-west1-b
```

#### Практика IaC с использованием Terraform(#ДЗ №6)

##### Устанавливаем Terraform распаковываем и добавляем бинарник в PATH.  
Проверяем установку командой
`terraform -v`

##### Создаем файл main.tf, который и будет главным конфигурационным файлом. В файл .gitignore добавляем все файлы Terraform, которых не должно быть в публичном репозитории
```
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```

##### Комманды Terraform:
```
terraform init - грузим провайдер 
terraform refresh - просмотр выходных переменных 
terraform output - просмотр значения выходных переменных
terraform destroy - удаление созданных ресурсов
terraform plan - просмотр вносимых изменений
terraform apply - применение изменений
terraform fmt - форматирование конфигурационных файлов
terraform show - стейт файл
```
##### Файлы:
```
Файл outputs.tf задать выходные переменные
Входные переменные определяются в файле variables.tf
terraform.tfvars - задаем переменные
```
#### Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform(#ДЗ №7)

##### Правила Firewall
'$ gcloud compute firewall-rules list' - просмотр правил на GCP

##### Импорт инфраструктуры из GCP в Terraform на примере правила Firewall
```
$ terraform import google_compute_firewall.firewall_ssh default-allow-ssh
google_compute_firewall.firewall_ssh: Importing from ID "default-allow-ssh"...
google_compute_firewall.firewall_ssh: Import complete!
Imported google_compute_firewall (ID: default-allow-ssh)
google_compute_firewall.firewall_ssh: Refreshing state... (ID: default-allowssh)
Import successful!
```
##### Виды зависимостей
```
Неявная зависимость
Ссылку в одном ресурсе на атрибуты другого тераформ
понимает как зависимость одного ресурса от другого. Это влияет
на очередность создания и удаления ресурсов при применении
изменений. Вновь пересоздадим все ресурсы и посмотрим на
очередность создания ресурсов сейчас 

Явная зависимость
Задается параметром `depends on`

```
##### Структуризация ресурсов
###### Необходимо создать 2 виртуальные машины.
Разбиваем файл main.tf на несколько конигурационных файлов:
```
Создаем файлы конфигурации VM app.tf и db.tf
Также вносим изменения в файл с переменными variables.tf
Выносим правило firewall в файл vpc.tf
```
##### Модули
Создаем модули db, app, vpc
В ~/terraform/main.tf добавляем секции вызова созданных модулей
`terraform get` - команда для загрузки модулей

#### Переиспользование модулей
##### Создаем Stage & Prod
Создаем 2 директории "stage" и "prod" в них копируем файлы main.tf, outputs.tf, terraform.tfvars из ~/terraform в main.tf меняем пути к модулям на ../modules/xxx

#### Реестр модулей
Реестр модулей для GCP: https://registry.terraform.io/
Создаем файл ~/terraform/storage-bucket.tf
```
provider "google" {
version = "2.0.0"
project = "${var.project}"
region = "${var.region}"
}
module "storage-bucket" {
source = "SweetOps/storage-bucket/google"
version = "0.1.1"
# Имена поменяйте на другие
name = ["storage-bucket-test", "storage-bucket-test2"]
}
output storage-bucket_url {
value = "${module.storage-bucket.url}"
}
```
#### Управление конфигурацией. Основные DevOps инструменты. Знакомство с Ansible.(ДЗ №8)

##### Установка Ansible
```
Устанавливаем python 2.7
Пакетный менеджер pip
С помощью pip или apt ставим ansible версии 2.4 или выше
Для управления VM используется ssh, версия python на машинах должна быть не ниже 2.7
```
##### Конфигурация Ansible
```
Inventory file - описываем какими машинами управлять
ansible.cfg - файл конфигурации ansible

```

##### Команды Ansible
```
ansible appserver -i ./inventory -m ping - тест ssh соединения
ansible dbserver -m command -a uptime - отправка комманды на удаленный хост
ansible app -m ping - проверка группы хостов
ansible app -m shell -a 'ruby -v; bundler -v' - подключение с помощью шелл
ansible db -m systemd -a name=mongod - модуль systemd предназначен для управления сервисами
ansible db -m service -a name=mongod - модуль service используется для управлениями сервисами на более старых машинах
```
Проверен запуск плейбука после удаления папки с проектом на хосте app. При повторном запуске плейбука отображается и подсвечивается статус "changed=1" (т.е. одно изменение)

#### Деплой и управление кофигурацией с Ansible (ДЗ №9)
```
Основное преимущество Ansible заключается в том, что
данный инструмент позволяет нам применять практику IaC,
давая возможность декларативно описывать желаемое
состояние наших систем в виде кода.
Код Ansible хранится в YAML файлах, называемых
плейбуками (playbooks) в терминологии Ansible.
```
Желательно использовать теги для задач, чтобы запускать отдельные таски, а не весь сценарий
Шаблоны в Ansible имеют формат *.j2

##### Команды Ansible
```
ansible-playbook --check - пробный запуск playbook
--limit -ограничивает группу хостов для применения плейбука
--tags указывает нужный таск
```
##### Handlers:
```
Похожи на таски, однако запускаются только по
оповещению от других задач.
Таск шлет оповещение handler-у в случае, когда он меняет
свое состояние. По этой причине handlers удобно использовать
для перезапуска сервисов.
Это, например, позволяет перезапускать сервис, только в
случае если поменялся его конфиг-файл.
```
Playbook который разбит на несколько сценариев(с объединенными задачами по действиям) и каждому сценарию назначен свой тэг удобнее в использовании для небольших проектах.
В крупных инфраструктурах лучше использовать несколько playbook разбивая задачи

- #### Ansible: Работа с ролями и окружениями (ДЗ №10)

##### Роли
```
Роли представляют собой основной механизм группировки и
переиспользования конфигурационного кода в Ansible.
Роли позволяют сгруппировать в единое целое описание
конфигурации отдельных сервисов и компонент системы (таски,
хендлеры, файлы, шаблоны, переменные). Роли можно затем
переиспользовать при настройке окружений, тем самым избежав
дублирования кода.
```
##### Ansible Galaxy
Это централизованное место, где хранится
информация о ролях, созданных сообществом (community roles).
`ansible-galaxy -h` - получить справку
`ansible-galaxy init`- создает структуру роли в соответствии с принятым форматом.

Структура роли:
```
db
├── README.md
├── defaults # <-- Директория для переменных по умолчанию
│ └── main.yml
├── handlers
│ └── main.yml
├── meta # <-- Информация о роли, создателе и зависимостях
│ └── main.yml
├── tasks # <-- Директория для тасков
│ └── main.yml
├── tests
│ ├── inventory
│ └── test.yml
└── vars # <-- Директория для переменных, которые не должны
└── main.yml # переопределяться пользователем
```

##### Окружения
Обычно инраструктура состоит из нескольких окружений(Prod,Dev,Test,Stage)
Необходимо создать свой inventory файл для каждого из окружений.
Строка запуска из окружения: `ansible-playbook -i environments/prod/inventory deploy.yml`
Best practice хранить playbooks в отдельной директории.
Запуск playbook для определенного окружения: `ansible-playbook -i environments/stage/inventory.yml playbooks/site.yml`
Хорошей практикой является разделение зависимостей ролей (requirements.yml) по окружениям.
Для открытия 80 порта в инстансе reddit-app в терраформ модуле app воспользовался тэгом http-server 

##### Ansible Vault
```
Обязательно добавьте в .gitignore файл vault.key. А
еще лучше - храните его out-of-tree, аналогично ключам SSH
(например, в папке ~/.ansible/vault.key)
```
#### Разработка и тестирование Ansible ролей и плейбуков (ДЗ №11)

##### Локальная разработка с Vagrant
Установим Vagrant скачав дистрибутив с оф.сайта
Описание характеристик VM содержаться в файле Vagrantfile, который лежит в директории ansible
Vagrant поддерживает большое количество провижинеров, которые позволяют автоматизировать процесс конфигурации
созданных VMs с использованием популярных инструментов управления конфигурацией и обычных скриптов на bash.
```
vagrant up - создает VM из файла Vagrantfile, если на машине нет образов, то они скачиваются автоматом
vagrant destroy -f - удаление VM
vagrant box list - показывает список скачанных образов
vagrant status - проверка статуса VM
vagrant ssh "имя VM" - подключение по ssh
vagrant provision "имя машины" - запуск только провижинга для определенной VM
```
Vagrant динамически генерирует инвентори файл для провижининга в соответствии с конфигурацией в Vagrantfile. 

##### Тестирование ролей
Для локального тестирования Ansible ролей использовуем Molecule для создания машин и проверки конфигурации и Testinfra для написания тестов.
Устанавливаем Virtualenv(это инструмент для создания изолированных сред Python) и в ней ставим python
Команды Molecule:
```
molecule init - создание заготовки тестов. Генерирует плейбук для применения нашей роли(~/playbook.yml)
molecule create - создание тестовой машины(описание в ~/molecule.yml)
molecule list - список машин
molecule login -h <name VM> - подключение внутрь машинки по ssh
molecule converge - применим playbook.yml, в котором вызывается наша роль к созданному хосту
molecule verify - прогонка тестов
```
Модули Testinfra используются для проверки конфигурации
