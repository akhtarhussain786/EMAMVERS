<?php
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/utils/system_settings.php';
require_once __DIR__ . '/../../api/services/SmsService.php';
require_once __DIR__ . '/../../api/services/PaymentService.php';

$action = $_GET['action'] ?? '';
$body = getBody();
$adminId = adminCurrentUserId();

switch ($action) {
    case 'get_settings':
        $settings = SystemSettings::getAll(true);
        ajaxOk($settings, 'Settings loaded successfully');
        break;

    case 'save_sms_settings':
        $enabled = !empty($body['sms_enabled']) ? '1' : '0';
        $provider = trim($body['sms_provider'] ?? 'fast2sms');
        $apiKey = trim($body['sms_api_key'] ?? '');
        $senderId = trim($body['sms_sender_id'] ?? 'EXAMVR');
        $templateId = trim($body['sms_template_id'] ?? '');
        $entityId = trim($body['sms_entity_id'] ?? '');
        $route = trim($body['sms_route'] ?? 'otp');

        SystemSettings::set('sms_enabled', $enabled, false, 'sms', 'Enable/disable SMS gateway');
        SystemSettings::set('sms_provider', $provider, false, 'sms', 'SMS Provider');
        SystemSettings::set('sms_sender_id', $senderId, false, 'sms', 'SMS Sender ID / Header');
        SystemSettings::set('sms_template_id', $templateId, false, 'sms', 'SMS Template ID');
        SystemSettings::set('sms_entity_id', $entityId, false, 'sms', 'DLT Entity ID');
        SystemSettings::set('sms_route', $route, false, 'sms', 'Fast2SMS Route');

        // Only update API Key if user provided a new unmasked string
        if (!empty($apiKey) && strpos($apiKey, '****') === false) {
            SystemSettings::set('sms_api_key', $apiKey, true, 'sms', 'SMS Gateway API Key');
        }

        auditLog(Database::getConnection(), $adminId, 'UPDATE_SETTINGS', 'SMS', "Updated SMS settings (Provider: $provider, Enabled: $enabled)");
        ajaxOk(null, 'SMS Gateway settings updated successfully!');
        break;

    case 'save_payment_settings':
        $enabled = !empty($body['payment_enabled']) ? '1' : '0';
        $mode = trim($body['payment_mode'] ?? 'mock');
        $cashfreeAppId = trim($body['cashfree_app_id'] ?? '');
        $cashfreeSecretKey = trim($body['cashfree_secret_key'] ?? '');
        $cashfreeWebhookSecret = trim($body['cashfree_webhook_secret'] ?? '');
        $currency = trim($body['payment_currency'] ?? 'INR');

        SystemSettings::set('payment_enabled', $enabled, false, 'payment', 'Enable live payments');
        SystemSettings::set('payment_mode', $mode, false, 'payment', 'Payment Mode (mock/test/live)');
        SystemSettings::set('cashfree_app_id', $cashfreeAppId, false, 'payment', 'Cashfree App ID');
        SystemSettings::set('payment_currency', $currency, false, 'payment', 'Payment Currency');

        if (!empty($cashfreeSecretKey) && strpos($cashfreeSecretKey, '••••') === false) {
            SystemSettings::set('cashfree_secret_key', $cashfreeSecretKey, true, 'payment', 'Cashfree Secret Key');
        }
        if (!empty($cashfreeWebhookSecret) && strpos($cashfreeWebhookSecret, '••••') === false) {
            SystemSettings::set('cashfree_webhook_secret', $cashfreeWebhookSecret, true, 'payment', 'Cashfree Webhook Secret');
        }

        auditLog(Database::getConnection(), $adminId, 'UPDATE_SETTINGS', 'PAYMENT', "Updated Payment settings (Mode: $mode, Enabled: $enabled)");
        ajaxOk(null, 'Payment Gateway settings updated successfully!');
        break;

    case 'save_general_settings':
        $appName = trim($body['app_name'] ?? 'EXAMVERSE');
        $supportEmail = trim($body['support_email'] ?? 'support@examverse.com');
        $supportPhone = trim($body['support_phone'] ?? '+91 9876543210');

        SystemSettings::set('app_name', $appName, false, 'general', 'Application Display Name');
        SystemSettings::set('support_email', $supportEmail, false, 'general', 'Support Email');
        SystemSettings::set('support_phone', $supportPhone, false, 'general', 'Support Phone');

        auditLog(Database::getConnection(), $adminId, 'UPDATE_SETTINGS', 'GENERAL', 'Updated general app settings');
        ajaxOk(null, 'General settings saved successfully!');
        break;

    case 'test_sms':
        $mobile = trim($body['test_mobile'] ?? '');
        if (empty($mobile)) {
            ajaxErr('Please provide a mobile number for testing.');
        }
        $testOtp = (string)random_int(100000, 999999);
        $res = SmsService::sendOtp($mobile, $testOtp);
        if ($res['success']) {
            ajaxOk($res, "Test SMS dispatched! Code: $testOtp (Provider: {$res['provider']})");
        } else {
            ajaxErr("Test SMS delivery failed: " . ($res['message'] ?? 'Gateway rejected request'));
        }
        break;

    case 'test_cashfree':
        $mode = PaymentService::getMode();
        if ($mode === 'mock') {
            ajaxOk(['mode' => 'mock'], 'Cashfree is in MOCK mode. Test order simulation succeeded.');
        }

        $res = PaymentService::createCashfreeOrder(1.00, 'test_cf_' . time(), [
            'customer_id'    => 'admin_test',
            'customer_phone' => '9876543210',
            'customer_email' => 'admin@examverse.com',
            'customer_name'  => 'Admin Test'
        ], 'Admin gateway test');

        if ($res['success']) {
            ajaxOk($res, "Cashfree API connection verified! Order ID: {$res['order_id']} (Environment: {$res['environment']})");
        } else {
            ajaxErr("Cashfree connection failed: " . ($res['message'] ?? 'Invalid App ID or Secret Key'));
        }
        break;

    default:
        ajaxErr("Unknown action '{$action}'", 404);
}
