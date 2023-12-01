const mongoose = require('mongoose');
const ProposedService = require('../models/ProposedService'); // Adjust the path as necessary
const nodemailer = require('nodemailer');
require('dotenv').config();

// Reusable database connection logic
let isConnectedBefore = false;

const connectToDatabase = async () => {
    // If already connected, use the existing connection
    if (mongoose.connection.readyState === 1) return;

    // If a connection attempt was made previously, wait for it
    if (isConnectedBefore) {
        await new Promise(resolve => setTimeout(resolve, 5000)); // 5 seconds delay
        if (mongoose.connection.readyState === 1) return;
    }

    // New connection
    await mongoose.connect(process.env.MONGO_CONNECT, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
    }).then(() => {
        isConnectedBefore = true;
    }, err => {
        console.error('Error connecting to database:', err);
    });
};

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

module.exports = async (req, res) => {
    await connectToDatabase();

    if (req.method === 'POST') {
        try {
            // Create and save the proposed service
            const newService = new ProposedService(req.body);
            await newService.save();

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
};
