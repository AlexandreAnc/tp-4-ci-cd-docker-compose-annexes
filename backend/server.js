const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const app = express();
const MONGODB_URI = process.env.MONGODB_URI || "mongodb://mongodb:27017/app";

app.use(cors());
app.use(express.json());

let db;
let messagesCollection;

async function connectDB() {
    const client = await MongoClient.connect(MONGODB_URI);
    db = client.db();
    messagesCollection = db.collection('messages');
    await messagesCollection.createIndex({ createdAt: -1 });
    console.log('Connected to MongoDB');
}

app.get('/api/message', async (req, res) => {
    try {
        const messages = await messagesCollection
            .find()
            .sort({ createdAt: -1 })
            .limit(10)
            .toArray();
        const last = messages[0];
        res.json({
            message: last ? last.text : 'Aucun message en base',
            messages
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/message', async (req, res) => {
    try {
        const { text } = req.body;
        if (!text) {
            return res.status(400).json({ error: 'text requis' });
        }
        const doc = { text, createdAt: new Date() };
        await messagesCollection.insertOne(doc);
        res.status(201).json(doc);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

connectDB()
    .then(() => {
        app.listen(3000, () => {
            console.log('Backend running on port 3000');
        });
    })
    .catch((err) => {
        console.error('MongoDB connection failed:', err);
        process.exit(1);
    });