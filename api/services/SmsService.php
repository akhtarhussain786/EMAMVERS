<?php
require_once __DIR__ . '/../utils/system_settings.php';
require_once __DIR__ . '/../config/config.php';

class SmsService {
    /**
     * Send OTP to a mobile number using the active configured gateway.
     * Returns: ['success' => bool, 'message' => string, 'provider' => string, 'details' => mixed]
     */
    public static function sendOtp(string $mobile, string $otp, string $appName = 'EXAMVERSE'): array {
        // Clean mobile number (strip +91 or spaces, keep 10 digits for Indian providers)
        $cleanMobile = preg_replace('/[^0-9]/', '', $mobile);
        if (strlen($cleanMobile) > 10 && substr($cleanMobile, 0, 2) === '91') {
            $cleanMobile = substr($cleanMobile, 2);
        }

        $enabled = (bool)SystemSettings::get('sms_enabled', false);
        $provider = strtolower((string)SystemSettings::get('sms_provider', 'fast2sms'));
        $apiKey = (string)SystemSettings::get('sms_api_key', '');

        // If SMS is not enabled or in dev mock mode or missing API key
        if (!$enabled || $provider === 'dev_mock' || empty($apiKey)) {
            error_log("[EXAMVERSE SMS DEV/MOCK] OTP for {$mobile}: {$otp}");
            return [
                'success' => true,
                'message' => 'OTP generated in dev/mock mode',
                'provider' => 'dev_mock',
                'dev_otp' => Config::isDebug() ? $otp : null
            ];
        }

        switch ($provider) {
            case 'fast2sms':
                return self::sendFast2Sms($cleanMobile, $otp, $apiKey);
            case 'msg91':
                return self::sendMsg91($cleanMobile, $otp, $apiKey);
            case 'twilio':
                return self::sendTwilio($mobile, $otp, $apiKey);
            default:
                return [
                    'success' => false,
                    'message' => "Unsupported SMS provider: {$provider}",
                    'provider' => $provider
                ];
        }
    }

    /**
     * Fast2SMS Gateway Integration (Quick OTP Route & DLT Route)
     */
    private static function sendFast2Sms(string $mobile, string $otp, string $apiKey): array {
        $route = SystemSettings::get('sms_route', 'otp');
        $senderId = SystemSettings::get('sms_sender_id', 'EXAMVR');
        $templateId = SystemSettings::get('sms_template_id', '');
        $entityId = SystemSettings::get('sms_entity_id', '');

        $url = 'https://www.fast2sms.com/dev/bulkV2';

        if ($route === 'dlt' && !empty($templateId)) {
            // DLT Route
            $postData = [
                'route' => 'dlt',
                'sender_id' => $senderId,
                'message' => $templateId,
                'variables_values' => $otp,
                'flash' => 0,
                'numbers' => $mobile
            ];
            if (!empty($entityId)) {
                $postData['entity_id'] = $entityId;
            }
        } else {
            // Quick OTP Route
            $postData = [
                'route' => 'otp',
                'variables_values' => $otp,
                'numbers' => $mobile
            ];
        }

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'authorization: ' . $apiKey,
            'Content-Type: application/json',
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err) {
            error_log("Fast2SMS cURL error: " . $err);
            return ['success' => false, 'message' => 'SMS gateway connection failed: ' . $err, 'provider' => 'fast2sms'];
        }

        $json = json_decode($response, true);
        $returnStatus = $json['return'] ?? false;
        $msg = $json['message'][0] ?? ($json['message'] ?? 'SMS sent status: ' . ($returnStatus ? 'Success' : 'Failed'));

        return [
            'success' => (bool)$returnStatus,
            'message' => is_array($msg) ? implode(', ', $msg) : (string)$msg,
            'provider' => 'fast2sms',
            'response' => $json
        ];
    }

    /**
     * MSG91 OTP Integration
     */
    private static function sendMsg91(string $mobile, string $otp, string $authKey): array {
        $templateId = SystemSettings::get('sms_template_id', '');
        
        if (!empty($templateId)) {
            $url = "https://control.msg91.com/api/v5/otp?template_id={$templateId}&mobile=91{$mobile}&otp={$otp}&authkey={$authKey}";
        } else {
            $url = "https://control.msg91.com/api/v5/otp?mobile=91{$mobile}&otp={$otp}&authkey={$authKey}";
        }

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err) {
            return ['success' => false, 'message' => 'MSG91 connection failed: ' . $err, 'provider' => 'msg91'];
        }

        $json = json_decode($response, true);
        $type = $json['type'] ?? '';
        return [
            'success' => ($type === 'success' || $httpCode === 200),
            'message' => $json['message'] ?? 'MSG91 Response received',
            'provider' => 'msg91',
            'response' => $json
        ];
    }

    /**
     * Twilio SMS Integration
     */
    private static function sendTwilio(string $mobile, string $otp, string $authToken): array {
        $accountSid = SystemSettings::get('sms_sender_id', ''); // Holds Twilio Account SID
        $fromNumber = SystemSettings::get('sms_template_id', ''); // Holds Twilio Sender Phone Number

        if (empty($accountSid) || empty($fromNumber)) {
            return ['success' => false, 'message' => 'Twilio requires Account SID in Sender ID field and Twilio Phone Number in Template ID field', 'provider' => 'twilio'];
        }

        $url = "https://api.twilio.com/2010-04-01/Accounts/{$accountSid}/Messages.json";
        $data = [
            'From' => $fromNumber,
            'To'   => (strpos($mobile, '+') === 0) ? $mobile : '+91' . $mobile,
            'Body' => "Your EXAMVERSE verification code is: {$otp}. Valid for 10 minutes."
        ];

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_USERPWD, "{$accountSid}:{$authToken}");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err) {
            return ['success' => false, 'message' => 'Twilio connection failed: ' . $err, 'provider' => 'twilio'];
        }

        $json = json_decode($response, true);
        $success = ($httpCode >= 200 && $httpCode < 300);
        return [
            'success' => $success,
            'message' => $success ? 'SMS sent via Twilio' : ($json['message'] ?? 'Twilio delivery failed'),
            'provider' => 'twilio',
            'response' => $json
        ];
    }
}
