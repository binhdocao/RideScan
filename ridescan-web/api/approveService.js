const mongoose = require('mongoose');
const ProposedService = require('../models/ProposedService'); // Adjust path as necessary
const TransportationService = require('../models/TransportationService'); // Adjust path as necessary
require('dotenv').config();

mongoose.connect(process.env.MONGO_CONNECT, { useNewUrlParser: true, useUnifiedTopology: true });

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));

module.exports = async (req, res) => {
    if (req.method === 'POST') {
        const serviceId = req.query.id; // Adjust according to how you pass the ID

        try {
            const proposedService = await ProposedService.findById(serviceId);
            if (!proposedService) {
                return res.status(404).send('Service not found');
            }

            // Transform proposedService document to fit the transportation schema
            const transportationData = {
                ride_method: "driving", // or other default value
                user_proposed: proposedService.user_proposed,
                send_to_application: true, // Assuming approval means it should be sent to application
                reviews: [], // Initialize with empty array or default values
                criteria: {
                    // Set default values or derive from proposedService data
                    // ...
                },
                name: proposedService.serviceName,
                // Add any other fields required by your transportation schema
            };

            // Create a new document in the transportation collection
            const newTransportationService = new TransportationService(transportationData);
            await newTransportationService.save();

            // Remove the document from proposedServices collection
            await ProposedService.findByIdAndDelete(serviceId);

            res.send('Service approved and moved to transportation collection');
        } catch (error) {
            console.error(error);
            res.status(500).send('Error processing request');
        }
    } else {
        res.status(405).send('Method Not Allowed');
    }
};
