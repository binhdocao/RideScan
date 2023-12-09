import React, { useState } from 'react';
import axios from 'axios';
import logo from '../images/ridescan-logo.png';
import { useNavigate } from "react-router-dom";

function Form() {
    const navigate = useNavigate(); 

    const [serviceData, setServiceData] = useState({
        contactName: '',
        email: '',
        phoneNumber: '',
        user_proposed: true,
        send_to_application: false,
        serviceName: '',
        address: '',
        radius: '',
        comments: '',
        price: '', 
        pricingUnit: 'mile' 
    });

    const [errors, setErrors] = useState({});

    const validate = () => {
        let tempErrors = {};
        tempErrors.contactName = serviceData.contactName ? "" : "Contact Name is required";
        tempErrors.email = serviceData.email ? "" : "Email is required";
        tempErrors.phoneNumber = /^[0-9]{10}$/.test(serviceData.phoneNumber) ? "" : "Phone Number must be 10 digits";
        tempErrors.serviceName = serviceData.serviceName ? "" : "Service Name is required";
        tempErrors.address = serviceData.address ? "" : "Address is required";
        tempErrors.radius = /^\d+$/.test(serviceData.radius) ? "" : "Operational Radius must be an integer";
        setErrors(tempErrors);
        return Object.values(tempErrors).every(x => x === "");
    };

    const handleChange = (e) => {
        setServiceData({ ...serviceData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (validate()) {
            try {
                await axios.post('/api/proposedServices', serviceData);
                navigate('/submission-confirmation');
            } catch (error) {
                console.error('Error submitting data', error);
            }
        }
    };


    const formStyle = {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        backgroundColor: 'white',
        borderRadius: '5px',
        boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
        maxWidth: '400px',
        margin: '50px auto',
        border: '2px solid #800000'
    };

    const inputStyle = {
        margin: '10px 0',
        padding: '10px',
        width: '100%',
        borderRadius: '5px',
        border: '1px solid #800000', 
    };

    const buttonStyle = {
        backgroundColor: '#800000', 
        color: 'white',
        padding: '10px 20px',
        border: 'none',
        borderRadius: '5px',
        cursor: 'pointer',
        marginTop: '20px',
        width: '100%',
    };

    const flexContainerStyle = {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        margin: '10px 0',
        width: '105%', 
    };

    const priceInputStyle = {
        ...inputStyle,
        flex: 6, 
        marginRight: '10px', 
    };

    // Style for the dropdown
    const dropdownStyle = {
        ...inputStyle,
        flex: 2, 
        width: 'auto',
    };

    

    return (
        <div style={{ backgroundColor: '#fff', padding: '40px', textAlign: 'center' }}>
            <img src={logo} alt="RideScan Logo" style={{ maxWidth: '200px', marginBottom: '20px' }} />
            <h1 style={{ color: "#800000", textDecoration:"underline"}}>Service Submission Form</h1>
            <form onSubmit={handleSubmit} style={formStyle}>
                <input
                    style={inputStyle}
                    type="text"
                    name="contactName"
                    value={serviceData.contactName}
                    onChange={handleChange}
                    placeholder="Contact Name"
                />
                {errors.contactName && <div style={{ color: 'red' }}>{errors.contactName}</div>}

                <input
                    style={inputStyle}
                    type="email"
                    name="email"
                    value={serviceData.email}
                    onChange={handleChange}
                    placeholder="Email"
                />
                {errors.email && <div style={{ color: 'red' }}>{errors.email}</div>}

                <input
                    style={inputStyle}
                    type="text"
                    name="phoneNumber"
                    value={serviceData.phoneNumber}
                    onChange={handleChange}
                    placeholder="Phone Number"
                />
                {errors.phoneNumber && <div style={{ color: 'red' }}>{errors.phoneNumber}</div>}

                <input
                    style={inputStyle}
                    type="text"
                    name="serviceName"
                    value={serviceData.serviceName}
                    onChange={handleChange}
                    placeholder="Service Name"
                />
                {errors.serviceName && <div style={{ color: 'red' }}>{errors.serviceName}</div>}

                <input
                    style={inputStyle}
                    type="text"
                    name="address"
                    value={serviceData.address}
                    onChange={handleChange}
                    placeholder="Based Address"
                />
                {errors.address && <div style={{ color: 'red' }}>{errors.address}</div>}

                <input
                    style={inputStyle}
                    type="text"
                    name="radius"
                    value={serviceData.radius}
                    onChange={handleChange}
                    placeholder="Operational Radius"
                />
                {errors.radius && <div style={{ color: 'red' }}>{errors.radius}</div>}

                <div style={flexContainerStyle}>
                <input
                    style={priceInputStyle}
                    type="number"
                    name="price"
                    value={serviceData.price}
                    onChange={handleChange}
                    placeholder="Price"
                />
                {errors.price && <div style={{ color: 'red' }}>{errors.price}</div>}

                <select
                    style={dropdownStyle}
                    name="pricingUnit"
                    value={serviceData.pricingUnit}
                    onChange={handleChange}
                >
                    <option value="mile">Per Mile</option>
                    <option value="ride">Per Ride</option>
                </select>
            </div>

                <textarea
                    style={{ ...inputStyle, height: '100px' }} 
                    name="comments"
                    value={serviceData.comments}
                    onChange={handleChange}
                    placeholder="Additional Comments"
                />

                <button style={buttonStyle} type="submit">Submit Proposal</button>
            </form>
        </div>
    );
}

export default Form;