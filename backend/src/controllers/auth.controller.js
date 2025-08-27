import User from '../models/User.js';

// POST /api/login.php -> { phone }
export async function login(req, res) {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ success: false, message: 'phone required' });

  let user = await User.findOne({ phone });
  if (!user) {
    user = await User.create({ phone });
  }
  return res.json({ success: true, message: 'OK', user_id: user._id.toString() });
}

// POST /api/get_user_id_by_phone.php -> { phone }
export async function getUserIdByPhone(req, res) {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ success: false, message: 'phone required' });
  const user = await User.findOne({ phone });
  if (!user) return res.json({ success: false, message: 'user not found' });
  return res.json({ success: true, user_id: user._id.toString() });
}
