const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Connect to MongoDB
mongoose.connect("mongodb+srv://rideuser:rideuser123@ridescan.zvz8zbl.mongodb.net/ridescan?retryWrites=true&w=majority");

// Define a schema
const proposedServiceSchema = new mongoose.Schema({
    contactName: String,
    email: String,
    phoneNumber: String,
    user_proposed: Boolean,
    send_to_application: Boolean,
    serviceName: String,
    address: String,
    radius: String,
    comments: String
});

// Create a model for proposed services
const ProposedService = mongoose.model('ProposedService', proposedServiceSchema, 'proposedServices');

// Endpoint to handle proposed services data submission
app.post('/proposedServices', async (req, res) => {
    const newService = new ProposedService(req.body);
    try {
        await newService.save();
        res.status(201).send("Proposed service data saved");
    } catch (error) {
        res.status(500).send(error);
    }
});


const PORT = 5500;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
