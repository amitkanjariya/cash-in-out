import Customer from '../models/Customer.js';
import User from '../models/User.js';
import { buildUploadUrl } from '../utils/urls.js';

// POST /api/add_customer_contact.php { user_id, phone, name }
export async function addCustomerContact(req, res) {
  const { user_id, phone, name } = req.body;
  if (!user_id || !phone || !name) {
    return res.status(400).json({ success: false, message: 'user_id, phone and name required' });
  }
  const user = await User.findById(user_id);
  if (!user) return res.json({ success: false, message: 'user not found' });

  let customer = await Customer.findOne({ user: user._id, phone });
  if (!customer) {
    customer = await Customer.create({ user: user._id, phone, name });
    return res.json({ success: true, message: 'Customer added', customer_id: customer._id.toString() });
  }
  // If exists, optionally update name
  if (name && name !== customer.name) {
    customer.name = name;
    await customer.save();
  }
  return res.json({ success: true, message: 'Customer already exists', customer_id: customer._id.toString() });
}

// POST /api/get_customer_details.php { user_id, customer_id }
export async function getCustomerDetails(req, res) {
  const { user_id, customer_id } = req.body;
  if (!user_id || !customer_id) return res.status(400).json({ success: false, message: 'user_id and customer_id required' });
  const customer = await Customer.findOne({ _id: customer_id, user: user_id });
  if (!customer) return res.json({ success: false, message: 'not found' });
  return res.json({
    success: true,
    data: {
      id: customer._id.toString(),
      name: customer.name,
      phone: customer.phone,
      profile_image: customer.profile_image ? buildUploadUrl(customer.profile_image) : null,
    },
  });
}

// POST /api/update_customer_profile.php multipart { user_id, customer_id, name, phone, profile_image }
export async function updateCustomerProfile(req, res) {
  const { user_id, customer_id, name, phone } = req.body;
  if (!user_id || !customer_id) return res.status(400).json({ success: false, message: 'user_id and customer_id required' });
  const update = { };
  if (name !== undefined) update.name = name;
  if (phone !== undefined) update.phone = phone;
  if (req.file) update.profile_image = req.file.filename;

  const customer = await Customer.findOneAndUpdate({ _id: customer_id, user: user_id }, update, { new: true });
  if (!customer) return res.json({ success: false, message: 'not found' });
  return res.json({ success: true, message: 'Profile updated', data: { profile_image: buildUploadUrl(customer.profile_image) } });
}
