const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Connect to MongoDB
mongoose.connect("mongodb+srv://rideuser:rideuser123@ridescan.zvz8zbl.mongodb.net/?retryWrites=true&w=majority", {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

// Define a schema
const userSchema = new mongoose.Schema({
    name: String,
    phoneNumber: String,
    email: String
});

// Create a model
const User = mongoose.model('User', userSchema);

// Endpoint to handle user data submission
app.post('/submit', async (req, res) => {
    const newUser = new User(req.body);
    try {
        await newUser.save();
        res.status(201).send("User data saved");
    } catch (error) {
        res.status(500).send(error);
    }
});

const PORT = 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
