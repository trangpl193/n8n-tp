const { Client } = require('pg');

async function testDevConnection() {
    const client = new Client({
        host: 'localhost',
        port: 5432,
        database: 'strangematic_n8n_dev',
        user: 'strangematic_dev',
        password: 'dev_secure_2024!'
    });

    try {
        await client.connect();
        console.log('✅ Development database connection successful!');
        
        const result = await client.query('SELECT NOW() as current_time, current_database() as db_name');
        console.log('📅 Current time:', result.rows[0].current_time);
        console.log('🗄️ Database:', result.rows[0].db_name);
        
    } catch (error) {
        console.error('❌ Development database connection failed:', error.message);
    } finally {
        await client.end();
    }
}

testDevConnection();
