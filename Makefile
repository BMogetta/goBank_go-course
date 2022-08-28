DB_URL=postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable

mysql:
	docker run --name mysql8 -p 3306:3306  -e MYSQL_ROOT_PASSWORD=secret -d mysql:8

createdb:
	docker exec -it postgres createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres dropdb simple_bank

migrateup:
	migrate -path postgres/migration -database "$(DB_URL)" -verbose up

migrateup1:
	migrate -path postgres/migration -database "$(DB_URL)" -verbose up 1

migratedown:
	migrate -path postgres/migration -database "$(DB_URL)" -verbose down

migratedown1:
	migrate -path postgres/migration -database "$(DB_URL)" -verbose down 1

db_docs:
	dbdocs build postgres/doc/db.dbml

db_schema:
	dbml2sql --postgres -o postgres/doc/schema.sql postgres/doc/db.dbml

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

server:
	go run main.go

mock:
	mockgen -package mockdb -destination postgres/mock/store.go github.com/BMogetta/Simple_bank/postgres/sqlc Store

proto:
	rm -f pb/*.go
	rm -f doc/swagger/*.swagger.json
	protoc --proto_path=proto --go_out=pb --go_opt=paths=source_relative \
	--go-grpc_out=pb --go-grpc_opt=paths=source_relative \
	--grpc-gateway_out=pb --grpc-gateway_opt=paths=source_relative \
	--openapiv2_out=doc/swagger --openapiv2_opt=allow_merge=true,merge_file_name=simple_bank \
	proto/*.proto
	statik -src=./doc/swagger -dest=./doc

evans:
	evans --host localhost --port 9090 -r repl

.PHONY: createdb dropdb migrateup migratedown migrateup1 migratedown1 db_docs db_schema sqlc test server mock proto evans