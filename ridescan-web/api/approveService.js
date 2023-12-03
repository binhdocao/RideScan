import { connectToDatabase } from '../mongodb';
import { ObjectId } from 'mongodb'; // Required to handle _id correctly

export default async function handler(req, res) {
    if (req.method === 'POST') {
        // Extract ID from the URL path
        const serviceId = req.query.id;

        try {
            const { database } = await connectToDatabase();
            const proposedServicesCollection = database.collection('proposedServices');
            const transportationServicesCollection = database.collection('transportation');

            const proposedService = await proposedServicesCollection.findOne({ _id: new ObjectId(serviceId) });
            if (!proposedService) {
                return res.status(404).send('Service not found');
            }

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

            // Create a new document in the transportation collection
            await transportationServicesCollection.insertOne(transportationData);

            // Remove the document from proposedServices collection
            await proposedServicesCollection.deleteOne({ _id: new ObjectId(serviceId) });

            res.send('Service approved and moved to transportation collection');
        } catch (error) {
            console.error(error);
            res.status(500).send('Error processing request');
        }
    } else {
        res.status(405).send('Method Not Allowed');
    }
}
