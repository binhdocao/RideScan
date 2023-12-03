import { connectToDatabase } from '../mongodb';
import { ObjectId } from 'mongodb'; // Required to handle _id correctly
require('dotenv').config();

export default async function handler(req, res) {
    if (req.method === 'POST') {
        // Extract ID from the request body
        const { serviceId } = req.body;
        console.log("serviceId:", serviceId);
        if (!serviceId) {
            console.error("Error: Service ID is required in the request body");
            return res.status(400).send('Service ID is required');
        }

        try {
            const { database } = await connectToDatabase();
            const proposedServicesCollection = database.collection('proposedServices');
            const transportationServicesCollection = database.collection('transportation');

            console.log("Finding proposed service with ID:", serviceId);
            const proposedService = await proposedServicesCollection.findOne({ _id: new ObjectId(serviceId) });
            if (!proposedService) {
                console.error("Error: Proposed service not found for ID:", serviceId);
                return res.status(404).send('Service not found');
            }

            console.log("Transforming proposed service data for ID:", serviceId);
            // Transform proposedService document to fit the transportation schema
            const transportationData = {
                ride_method: "driving", // default value or derived from proposedService data
                user_proposed: proposedService.user_proposed,
                send_to_application: true, // Assuming approval means it should be sent to application
                reviews: [], // Initialize with empty array
                criteria: {
                    // Set default values or derive from proposedService data
                    // ...
                },
                name: proposedService.serviceName, // Derived from proposedService
                contactName: proposedService.contactName,
                email: proposedService.email,
                phoneNumber: proposedService.phoneNumber,
                address: proposedService.address,
                radius: proposedService.radius,
                comments: proposedService.comments
                // Add any other fields required by your transportation schema
            };

            console.log("Inserting new transportation document for ID:", serviceId);
            // Create a new document in the transportation collection
            await transportationServicesCollection.insertOne(transportationData);

            console.log("Removing proposed service document for ID:", serviceId);
            // Remove the document from proposedServices collection
            await proposedServicesCollection.deleteOne({ _id: new ObjectId(serviceId) });

            console.log("Service approved and moved to transportation collection for ID:", serviceId);
            res.send('Service approved and moved to transportation collection');
        } catch (error) {
            console.error("Error occurred:", error);
            res.status(500).send('Error processing request');
        }
    } else {
        console.error("Error: Method Not Allowed");
        res.status(405).send('Method Not Allowed');
    }
}
