#!/usr/bin/env node

const http = require('http');
const ip = require('ip');
const sqlite3 = require('sqlite3');
const dayjs = require('dayjs');
const DB_PATH = process.env.DB_PATH || ".";

const server = http.createServer();

const createTables = (db) => {
    db.exec(`
        create table if not exists requests (
            ip text not null,
            date test not null,
            body text
        );
    `, () => { console.log("Table 'requests' has been created")})
}

const connectDB = () => {
    const db = new sqlite3.Database(`${DB_PATH}/mabaya.db`, sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE, (err, db) => {
        if (err) {
            console.log("Getting error " + err);
            exit(1);
        }
        console.log(`Connected to DB ${DB_PATH}/mabaya.db`)
    });
    createTables(db)
    return db;
}

const updateDB = (db, ip, body) => {
    db.exec(`
        insert into requests (ip, date, body)
        values ('${ip}', '${now()}', '${body}');
    `, () => {console.log(`Updated DB ${DB_PATH}/mabaya.db with values '${ip}', '${now()}', '${body}'`)})
}

const now = () => {
    return dayjs().format("YYYY-MM-DD h:mm:ss")
}

const end = (response, data) => {
    response.write(JSON.stringify(data));
    response.end();
}

const db = connectDB();
server.on('request', (request, response) => {
    let body = [];
    const data = {};

    request.on('data', (chunk) => {
        body.push(chunk);
    }).on('end', () => {
        body = Buffer.concat(body).toString();
        switch (request.url) {
            case '/health':
                data.status = "OK";
                end(response, data);
                break;
            case '/v1/api/healthcheck/alive':
                data.status = "OK";
                end(response, data);
                break;
            case '/showdb':
                db.all('select * from requests;', [], (err, rows) => {
                    if (err) {throw err;}
                    data.rows = rows;
                    end(response, data);
                });
            break;
            default: 
                updateDB(db, ip.address(), body);
                console.log(`==== ${request.method} ${request.url} ${ip.address()}`);
                console.log('> Headers');
                console.log(request.headers);
                console.log('> Body');
                console.log(body);
                data.server_ip = ip.address();
                data.body = body;
                end(response, data);
            }
    });
}).listen(8080);
