<?php
require_once __DIR__ . '/../../api/config/db.php';
require_once __DIR__ . '/../../api/utils/system_settings.php';
require_once __DIR__ . '/../includes/session.php';

$csrfToken = adminCsrfToken();
$allSettings = SystemSettings::getAll(true);

$sms = $allSettings['sms'] ?? [];
$payment = $allSettings['payment'] ?? [];
$general = $allSettings['general'] ?? [];

$smsEnabled = !empty($sms['sms_enabled']['value']) && $sms['sms_enabled']['value'] == '1';
$smsProvider = $sms['sms_provider']['value'] ?? 'fast2sms';

$paymentEnabled = !empty($payment['payment_enabled']['value']) && $payment['payment_enabled']['value'] == '1';
$paymentMode = $payment['payment_mode']['value'] ?? 'mock';
?>

<style>
.settings-container {
    max-width: 1000px;
    margin: 0 auto;
    padding-bottom: 40px;
}
.settings-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 24px;
    flex-wrap: wrap;
    gap: 16px;
}
.settings-nav {
    display: flex;
    gap: 8px;
    border-bottom: 1px solid var(--border, rgba(0,0,0,0.08));
    margin-bottom: 24px;
    padding-bottom: 0px;
}
.settings-tab-btn {
    padding: 12px 20px;
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
    font-weight: 600;
    font-size: 14px;
    color: var(--text-muted, #64748b);
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    transition: all 0.2s ease;
}
.settings-tab-btn:hover {
    color: var(--text-main, #0f172a);
}
.settings-tab-btn.active {
    color: var(--primary, #6366f1);
    border-bottom-color: var(--primary, #6366f1);
}
.settings-card {
    background: #ffffff;
    border-radius: 12px;
    border: 1px solid var(--border, #e2e8f0);
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    padding: 24px;
    margin-bottom: 24px;
}
.card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding-bottom: 16px;
    border-bottom: 1px solid #f1f5f9;
}
.card-title {
    font-size: 18px;
    font-weight: 700;
    color: #1e293b;
    margin: 0;
    display: flex;
    align-items: center;
    gap: 10px;
}
.card-desc {
    font-size: 13px;
    color: #64748b;
    margin-top: 4px;
}
.form-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 20px;
}
.form-group {
    margin-bottom: 18px;
}
.form-group label {
    display: block;
    font-size: 13px;
    font-weight: 600;
    color: #334155;
    margin-bottom: 6px;
}
.form-control {
    width: 100%;
    padding: 10px 14px;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
    font-size: 14px;
    transition: all 0.2s;
    box-sizing: border-box;
    background: #ffffff;
}
.form-control:focus {
    border-color: #6366f1;
    outline: none;
    box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
}
.form-hint {
    font-size: 12px;
    color: #94a3b8;
    margin-top: 4px;
}
.switch-wrapper {
    display: flex;
    align-items: center;
    gap: 12px;
}
.switch {
    position: relative;
    display: inline-block;
    width: 46px;
    height: 24px;
}
.switch input {
    opacity: 0;
    width: 0;
    height: 0;
}
.slider {
    position: absolute;
    cursor: pointer;
    top: 0; left: 0; right: 0; bottom: 0;
    background-color: #cbd5e1;
    transition: .3s;
    border-radius: 24px;
}
.slider:before {
    position: absolute;
    content: "";
    height: 18px;
    width: 18px;
    left: 3px;
    bottom: 3px;
    background-color: white;
    transition: .3s;
    border-radius: 50%;
}
input:checked + .slider {
    background-color: #10b981;
}
input:checked + .slider:before {
    transform: translateX(22px);
}
.btn-save {
    background: #6366f1;
    color: #fff;
    border: none;
    padding: 10px 22px;
    border-radius: 8px;
    font-weight: 600;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.2s;
    display: inline-flex;
    align-items: center;
    gap: 8px;
}
.btn-save:hover {
    background: #4f46e5;
}
.btn-outline {
    background: #f8fafc;
    color: #334155;
    border: 1px solid #cbd5e1;
    padding: 10px 18px;
    border-radius: 8px;
    font-weight: 600;
    font-size: 13px;
    cursor: pointer;
    transition: all 0.2s;
    display: inline-flex;
    align-items: center;
    gap: 6px;
}
.btn-outline:hover {
    background: #f1f5f9;
    border-color: #94a3b8;
}
.badge-status {
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
}
.badge-live {
    background: #dcfce7;
    color: #15803d;
}
.badge-mock {
    background: #fef3c7;
    color: #b45309;
}
.badge-off {
    background: #f1f5f9;
    color: #64748b;
}
.toast-msg {
    position: fixed;
    bottom: 24px;
    right: 24px;
    padding: 12px 20px;
    border-radius: 8px;
    background: #1e293b;
    color: #fff;
    font-size: 14px;
    font-weight: 500;
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
    z-index: 9999;
    display: none;
    animation: fadeIn 0.3s;
}
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
</style>

<div class="settings-container">
    <div class="settings-header">
        <div>
            <h1 style="font-size:24px;font-weight:800;color:#0f172a;margin:0 0 4px 0;">Platform Settings</h1>
            <p style="color:#64748b;margin:0;font-size:14px;">Manage SMS gateways, Razorpay payment processing, and system credentials.</p>
        </div>
        <div style="display:flex;gap:10px;">
            <span class="badge-status <?php echo $smsEnabled ? 'badge-live' : 'badge-off'; ?>">
                SMS: <?php echo $smsEnabled ? strtoupper($smsProvider) : 'OFF (MOCK)'; ?>
            </span>
            <span class="badge-status <?php echo $paymentEnabled ? ($paymentMode==='live'?'badge-live':'badge-mock') : 'badge-off'; ?>">
                Payment: <?php echo $paymentEnabled ? strtoupper($paymentMode) : 'DISABLED'; ?>
            </span>
        </div>
    </div>

    <!-- Tab Navigation -->
    <div class="settings-nav">
        <button class="settings-tab-btn active" onclick="showTab('sms-tab', this)">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/></svg>
            SMS Gateway
        </button>
        <button class="settings-tab-btn" onclick="showTab('payment-tab', this)">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg>
            Payment Gateway (Razorpay)
        </button>
        <button class="settings-tab-btn" onclick="showTab('general-tab', this)">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            General App Settings
        </button>
    </div>

    <!-- TAB 1: SMS GATEWAY -->
    <div id="sms-tab" class="tab-content">
        <form id="smsForm" onsubmit="saveSmsSettings(event)">
            <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars($csrfToken); ?>">
            <div class="settings-card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">
                            <span style="color:#6366f1;">📲</span> SMS Gateway Configuration
                        </h2>
                        <div class="card-desc">Configure automated mobile OTP and SMS notifications for student login and registrations.</div>
                    </div>
                    <div class="switch-wrapper">
                        <span style="font-size:13px;font-weight:600;color:#334155;">Enable Live SMS</span>
                        <label class="switch">
                            <input type="checkbox" name="sms_enabled" id="sms_enabled" <?php echo $smsEnabled ? 'checked' : ''; ?>>
                            <span class="slider"></span>
                        </label>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="sms_provider">Active SMS Provider</label>
                        <select name="sms_provider" id="sms_provider" class="form-control" onchange="updateSmsFields()">
                            <option value="fast2sms" <?php echo $smsProvider==='fast2sms'?'selected':''; ?>>Fast2SMS (India)</option>
                            <option value="msg91" <?php echo $smsProvider==='msg91'?'selected':''; ?>>MSG91 (India / Global)</option>
                            <option value="twilio" <?php echo $smsProvider==='twilio'?'selected':''; ?>>Twilio (International)</option>
                            <option value="dev_mock" <?php echo $smsProvider==='dev_mock'?'selected':''; ?>>Local Dev Mock (Console/Log Only)</option>
                        </select>
                        <div class="form-hint">Select the SMS API gateway used for sending OTPs.</div>
                    </div>

                    <div class="form-group" id="group_sms_route">
                        <label for="sms_route">Fast2SMS Route</label>
                        <select name="sms_route" id="sms_route" class="form-control">
                            <option value="otp" <?php echo ($sms['sms_route']['value']??'')==='otp'?'selected':''; ?>>Quick OTP (No DLT required)</option>
                            <option value="dlt" <?php echo ($sms['sms_route']['value']??'')==='dlt'?'selected':''; ?>>DLT Manual / Template Route</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="sms_api_key">API Key / Auth Token</label>
                        <input type="password" name="sms_api_key" id="sms_api_key" class="form-control" placeholder="<?php echo !empty($sms['sms_api_key']['value']) ? $sms['sms_api_key']['value'] : 'Enter API Key...'; ?>">
                        <div class="form-hint">Stored securely using AES-256 encryption. Leave blank to keep existing key.</div>
                    </div>

                    <div class="form-group">
                        <label for="sms_sender_id">Sender ID / Header / Twilio SID</label>
                        <input type="text" name="sms_sender_id" id="sms_sender_id" class="form-control" value="<?php echo htmlspecialchars($sms['sms_sender_id']['value'] ?? 'EXAMVR'); ?>" placeholder="e.g. EXAMVR or Twilio SID">
                        <div class="form-hint">6-character approved header name or Twilio Account SID.</div>
                    </div>

                    <div class="form-group" id="group_template_id">
                        <label for="sms_template_id">DLT Template ID / Twilio Phone</label>
                        <input type="text" name="sms_template_id" id="sms_template_id" class="form-control" value="<?php echo htmlspecialchars($sms['sms_template_id']['value'] ?? ''); ?>" placeholder="DLT Template ID or +1...">
                    </div>

                    <div class="form-group" id="group_entity_id">
                        <label for="sms_entity_id">DLT Principal Entity ID (PE ID)</label>
                        <input type="text" name="sms_entity_id" id="sms_entity_id" class="form-control" value="<?php echo htmlspecialchars($sms['sms_entity_id']['value'] ?? ''); ?>" placeholder="14-digit DLT Registration ID">
                    </div>
                </div>

                <div style="display:flex;justify-content:space-between;align-items:center;margin-top:20px;padding-top:16px;border-top:1px solid #f1f5f9;">
                    <button type="button" class="btn-outline" onclick="openTestSmsModal()">
                        <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/></svg>
                        Test SMS Delivery
                    </button>
                    <button type="submit" class="btn-save">Save SMS Settings</button>
                </div>
            </div>
        </form>
    </div>

    <!-- TAB 2: PAYMENT GATEWAY (RAZORPAY) -->
    <div id="payment-tab" class="tab-content" style="display:none;">
        <form id="paymentForm" onsubmit="savePaymentSettings(event)">
            <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars($csrfToken); ?>">
            <div class="settings-card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">
                            <span style="color:#0284c7;">💳</span> Razorpay Payment Gateway
                        </h2>
                        <div class="card-desc">Configure online payments for study notes, practice materials, and teacher subscriptions.</div>
                    </div>
                    <div class="switch-wrapper">
                        <span style="font-size:13px;font-weight:600;color:#334155;">Enable Gateway</span>
                        <label class="switch">
                            <input type="checkbox" name="payment_enabled" id="payment_enabled" <?php echo $paymentEnabled ? 'checked' : ''; ?>>
                            <span class="slider"></span>
                        </label>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="payment_mode">Payment Processing Mode</label>
                        <select name="payment_mode" id="payment_mode" class="form-control">
                            <option value="mock" <?php echo $paymentMode==='mock'?'selected':''; ?>>Mock Sandbox (Free Testing, No Gateway Call)</option>
                            <option value="test" <?php echo $paymentMode==='test'?'selected':''; ?>>Razorpay Test Mode (rzp_test_...)</option>
                            <option value="live" <?php echo $paymentMode==='live'?'selected':''; ?>>Razorpay Live Production (rzp_live_...)</option>
                        </select>
                        <div class="form-hint">Set to Test or Live to collect actual UPI, Card, and NetBanking payments.</div>
                    </div>

                    <div class="form-group">
                        <label for="payment_currency">Currency</label>
                        <input type="text" name="payment_currency" id="payment_currency" class="form-control" value="<?php echo htmlspecialchars($payment['payment_currency']['value'] ?? 'INR'); ?>" readonly>
                    </div>

                    <div class="form-group">
                        <label for="razorpay_key_id">Razorpay Key ID</label>
                        <input type="text" name="razorpay_key_id" id="razorpay_key_id" class="form-control" value="<?php echo htmlspecialchars($payment['razorpay_key_id']['value'] ?? ''); ?>" placeholder="rzp_test_... or rzp_live_...">
                        <div class="form-hint">Public Key ID from Razorpay Dashboard ➔ API Keys.</div>
                    </div>

                    <div class="form-group">
                        <label for="razorpay_key_secret">Razorpay Key Secret</label>
                        <input type="password" name="razorpay_key_secret" id="razorpay_key_secret" class="form-control" placeholder="<?php echo !empty($payment['razorpay_key_secret']['value']) ? $payment['razorpay_key_secret']['value'] : 'Enter Key Secret...'; ?>">
                        <div class="form-hint">Encrypted at rest with AES-256. Leave empty to preserve existing.</div>
                    </div>

                    <div class="form-group">
                        <label for="razorpay_webhook_secret">Razorpay Webhook Secret (Optional)</label>
                        <input type="password" name="razorpay_webhook_secret" id="razorpay_webhook_secret" class="form-control" placeholder="<?php echo !empty($payment['razorpay_webhook_secret']['value']) ? $payment['razorpay_webhook_secret']['value'] : 'Webhook Secret...'; ?>">
                        <div class="form-hint">Used for asynchronous payment capture & refund webhooks.</div>
                    </div>
                </div>

                <div style="display:flex;justify-content:space-between;align-items:center;margin-top:20px;padding-top:16px;border-top:1px solid #f1f5f9;">
                    <button type="button" class="btn-outline" onclick="testRazorpayConnection()">
                        <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                        Verify Credentials
                    </button>
                    <button type="submit" class="btn-save">Save Payment Settings</button>
                </div>
            </div>
        </form>
    </div>

    <!-- TAB 3: GENERAL SETTINGS -->
    <div id="general-tab" class="tab-content" style="display:none;">
        <form id="generalForm" onsubmit="saveGeneralSettings(event)">
            <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars($csrfToken); ?>">
            <div class="settings-card">
                <div class="card-header">
                    <div>
                        <h2 class="card-title">
                            <span style="color:#10b981;">⚙️</span> General App Configuration
                        </h2>
                        <div class="card-desc">Platform brand details and support contact numbers.</div>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="app_name">Application Name</label>
                        <input type="text" name="app_name" id="app_name" class="form-control" value="<?php echo htmlspecialchars($general['app_name']['value'] ?? 'EXAMVERSE'); ?>">
                    </div>
                    <div class="form-group">
                        <label for="support_email">Official Support Email</label>
                        <input type="email" name="support_email" id="support_email" class="form-control" value="<?php echo htmlspecialchars($general['support_email']['value'] ?? 'support@examverse.com'); ?>">
                    </div>
                    <div class="form-group">
                        <label for="support_phone">Official Support Phone</label>
                        <input type="text" name="support_phone" id="support_phone" class="form-control" value="<?php echo htmlspecialchars($general['support_phone']['value'] ?? '+91 9876543210'); ?>">
                    </div>
                </div>

                <div style="text-align:right;margin-top:20px;padding-top:16px;border-top:1px solid #f1f5f9;">
                    <button type="submit" class="btn-save">Save General Settings</button>
                </div>
            </div>
        </form>
    </div>
</div>

<div id="toast" class="toast-msg"></div>

<script>
const CSRF_TOKEN = '<?php echo $csrfToken; ?>';

function showTab(tabId, el) {
    document.querySelectorAll('.tab-content').forEach(t => t.style.display = 'none');
    document.querySelectorAll('.settings-tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById(tabId).style.display = 'block';
    el.classList.add('active');
}

function showToast(msg, isErr = false) {
    const t = document.getElementById('toast');
    t.innerText = msg;
    t.style.background = isErr ? '#ef4444' : '#1e293b';
    t.style.display = 'block';
    setTimeout(() => { t.style.display = 'none'; }, 4000);
}

function updateSmsFields() {
    const prov = document.getElementById('sms_provider').value;
    document.getElementById('group_sms_route').style.display = (prov === 'fast2sms') ? 'block' : 'none';
    document.getElementById('group_entity_id').style.display = (prov === 'fast2sms') ? 'block' : 'none';
}

async function saveSmsSettings(e) {
    e.preventDefault();
    const fd = new FormData(document.getElementById('smsForm'));
    const payload = {
        csrf_token: CSRF_TOKEN,
        sms_enabled: fd.get('sms_enabled') ? '1' : '0',
        sms_provider: fd.get('sms_provider'),
        sms_api_key: fd.get('sms_api_key'),
        sms_sender_id: fd.get('sms_sender_id'),
        sms_template_id: fd.get('sms_template_id'),
        sms_entity_id: fd.get('sms_entity_id'),
        sms_route: fd.get('sms_route')
    };

    try {
        const res = await fetch('ajax/settings.php?action=save_sms_settings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.status === 'success') {
            showToast(data.message);
        } else {
            showToast(data.message || 'Failed to save', true);
        }
    } catch (err) {
        showToast('Network error while saving SMS settings', true);
    }
}

async function savePaymentSettings(e) {
    e.preventDefault();
    const fd = new FormData(document.getElementById('paymentForm'));
    const payload = {
        csrf_token: CSRF_TOKEN,
        payment_enabled: fd.get('payment_enabled') ? '1' : '0',
        payment_mode: fd.get('payment_mode'),
        razorpay_key_id: fd.get('razorpay_key_id'),
        razorpay_key_secret: fd.get('razorpay_key_secret'),
        razorpay_webhook_secret: fd.get('razorpay_webhook_secret'),
        payment_currency: fd.get('payment_currency')
    };

    try {
        const res = await fetch('ajax/settings.php?action=save_payment_settings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.status === 'success') {
            showToast(data.message);
        } else {
            showToast(data.message || 'Failed to save', true);
        }
    } catch (err) {
        showToast('Network error while saving payment settings', true);
    }
}

async function saveGeneralSettings(e) {
    e.preventDefault();
    const fd = new FormData(document.getElementById('generalForm'));
    const payload = {
        csrf_token: CSRF_TOKEN,
        app_name: fd.get('app_name'),
        support_email: fd.get('support_email'),
        support_phone: fd.get('support_phone')
    };

    try {
        const res = await fetch('ajax/settings.php?action=save_general_settings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.status === 'success') {
            showToast(data.message);
        } else {
            showToast(data.message || 'Failed to save', true);
        }
    } catch (err) {
        showToast('Network error while saving general settings', true);
    }
}

async function openTestSmsModal() {
    const mobile = prompt('Enter a 10-digit mobile number to send test OTP:');
    if (!mobile) return;

    showToast('Sending test SMS...');
    try {
        const res = await fetch('ajax/settings.php?action=test_sms', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ csrf_token: CSRF_TOKEN, test_mobile: mobile })
        });
        const data = await res.json();
        if (data.status === 'success') {
            alert('✅ ' + data.message);
        } else {
            alert('❌ ' + (data.message || 'Test SMS failed'));
        }
    } catch (err) {
        alert('❌ Error: ' + err.message);
    }
}

async function testRazorpayConnection() {
    showToast('Verifying Razorpay credentials...');
    try {
        const res = await fetch('ajax/settings.php?action=test_razorpay', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ csrf_token: CSRF_TOKEN })
        });
        const data = await res.json();
        if (data.status === 'success') {
            alert('✅ ' + data.message);
        } else {
            alert('❌ ' + (data.message || 'Razorpay test failed'));
        }
    } catch (err) {
        alert('❌ Error: ' + err.message);
    }
}
</script>
