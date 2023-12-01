const mongoose = require('mongoose');
const ProposedService = require('../models/ProposedService');
const TransportationService = require('../models/TransportationService');
require('dotenv').config();

let db = mongoose.connection;

// Function to handle database connection
async function connectToDatabase() {
  if (db.readyState === 0) {
    await mongoose.connect(process.env.MONGO_CONNECT, { useNewUrlParser: true, useUnifiedTopology: true });
  }
}

module.exports = async (req, res) => {
    // Ensure database connection is established
    await connectToDatabase();
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
