// Minimal DB helper for tests that need to toggle a shop configuration row.
// The connection defaults mirror the shop-ce Playwright suite.

import mysql from 'mysql2/promise';

export class DatabaseHelper {
    constructor() {
        this.pool = mysql.createPool({
            host: process.env.DB_HOST ?? '127.0.0.1',
            port: Number(process.env.DB_PORT ?? 3306),
            user: process.env.DB_USER ?? 'root',
            password: process.env.DB_PASS ?? 'supersecret',
            database: process.env.DB_NAME ?? 'o3shop',
            waitForConnections: true,
            connectionLimit: 5,
            queueLimit: 0,
        });
    }

    async query(sql, params = []) {
        const [rows] = await this.pool.query(sql, params);
        return rows;
    }

    async execute(sql, params = []) {
        await this.pool.execute(sql, params);
    }

    async close() {
        await this.pool.end();
    }
}
