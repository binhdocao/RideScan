import { connectToDatabase } from '../mongodb';
import nodemailer from 'nodemailer';
require('dotenv').config();

// Nodemailer configuration
const transporter = nodemailer.createTransport({
    service: "gmail",
    host: "smtp.gmail.com",
    port: 587,
    secure: false,
    auth: {
        user: "ridescan.notifications@gmail.com",
        pass: process.env.EMAIL_APP_PASSWORD,
    },
});

export default async function handler(req, res) {
    if (req.method === 'POST') {
        try {
            const { database } = await connectToDatabase();
            const proposedServicesCollection = database.collection('proposedServices');

            // Insert the new proposed service
            const result = await proposedServicesCollection.insertOne(req.body);

            // Email options
            const mailOptions = {
                from: 'ridescan.notifications@gmail.com',
                to: req.body.email,
                subject: 'Submission Received',
                text: 'Your submission has been received. Please wait 1-2 business days for a response.'
            };

            // Send the email
            await transporter.sendMail(mailOptions);
            res.status(201).send('Proposed service data saved and email sent');
        } catch (error) {
            console.error('Error occurred:', error);
            res.status(500).send('Error processing request');
        }
    } else {
        // Handle non-POST requests
        res.status(405).send('Method Not Allowed');
    }
}
