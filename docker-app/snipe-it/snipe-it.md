version: '3.8'

services:
  snipe-db:
    image: docker.io/library/mariadb:10.11
    container_name: snipe-db
    restart: always
    volumes:
      - snipe-db-vol:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=cva23004599/
      - MYSQL_DATABASE=snipeit
      - MYSQL_USER=snipeit_user
      - MYSQL_PASSWORD=cva23004599/

  snipe-it:
    image: docker.io/snipe/snipe-it:latest
    container_name: snipe-it
    restart: always
    ports:
      - "9001:80"
    volumes:
      # Dito ise-save ang mga uploads, signatures, at assets mo
      - snipe-vol:/var/www/html/storage/app/uploads
      # Dito naman ang login/oauth security keys mo
      - snipe-keys-vol:/var/www/html/storage/oauth
    environment:
      - APP_URL=http://localhost:9001
      - APP_KEY=base64:x6u90gmHBT/sIpjV3YDKvSffeEaCFApa0X/RkarSpdg=
      - APP_TIMEZONE=Asia/Manila
      - DB_CONNECTION=mysql
      - DB_HOST=snipe-db
      - DB_DATABASE=snipeit
      - DB_USERNAME=snipeit_user
      - DB_PASSWORD=cva23004599/
      - DB_PORT=3306
    depends_on:
      - snipe-db

volumes:
  snipe-db-vol:
  snipe-vol:
  snipe-keys-vol:

