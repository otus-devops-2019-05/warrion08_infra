# warrion08_infra

# **Оглавление:**
### ДЗ №1 


#### ДЗ №1: Локальное окружение инженера. ChatOps и визуализация рабочих процессов. Командная работа с Git. Работа в GitHub.

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
Создаем в корне репозитория .yml файл, в котором описываем инструкции для сборки
`$ touch .travis.yml`
dist: trusty
sudo: required
language: bash
before_install:
- curl https://raw.githubusercontent.com/express42/otus-homeworks/2019-05/run.sh |
bash

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
Нотификация от Trevis приходит, но билд упал. Смотрим лог,проблема в функции test_equal() в test.py. Исправляем и коммитим. Билд успешно собран.
