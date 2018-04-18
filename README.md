# dns-aws-selectel
Scripts for backup DNS zones from AWS and load them to Selectel

Для выгрузки состава зоны из AWS Route53 нужно 
1. записать в ~/.aws/config данные для доступа к API примерно так
[default]
output = text
aws_secret_access_key = ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
region = eu-west-1
aws_access_key_id = XXXXXXXXXXXXXXXXXXXXX
2. Записать ZONE_ID в ./getAwsZone.sh , его видно в списке зон

Для заливки записей в Селектел
1. Создать пустой домен, например tralala.ru в ЛК Селектела
2. Заполнить константы в ./loadToSelectel.pl
my $DOMAIN = "tralala.ru"; - название домена
my $AWS_ZONE_BACKUP="backup/backup_2018-04-18-060001.json"; - файл бэкапа созданный скриптом ./getAwsZone.sh
my $SELECTEL_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"; - сгенерировать в ЛК Селектела

mkdir backup
./getAwsZone.sh
./loadToSelectel.pl
