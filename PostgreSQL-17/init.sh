sudo docker volume create pg-db-data
sudo docker run --name pg-db -p 5432:5432 --env-file .env -v pg-db-data:/var/lib/postgresql/data -d --restart unless-stopped postgres:17