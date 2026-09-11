<?php
require_once __DIR__ . '/../utils/system_settings.php';
require_once __DIR__ . '/../config/config.php';

class PaymentService {
    /**
     * Check if live payments are enabled
     */
    public static function isEnabled(): bool {
        return (bool)SystemSettings::get('payment_enabled', false);
    }

    /**
     * Get active payment mode: 'mock', 'test', 'live'
     */
    public static function getMode(): string {
        return strtolower((string)SystemSettings::get('payment_mode', 'mock'));
    }

    /**
     * Get Public Razorpay Key ID for client initialization
     */
    public static function getPublicKey(): string {
        return (string)SystemSettings::get('razorpay_key_id', '');
    }

    /**
     * Get Cashfree App ID / Client ID
     */
    public static function getCashfreeAppId(): string {
        return (string)SystemSettings::get('cashfree_app_id', '');
    }

    /**
     * Get Cashfree Secret Key
     */
    public static function getCashfreeSecretKey(): string {
        return (string)SystemSettings::get('cashfree_secret_key', '');
    }

    /**
     * Get Cashfree Environment ('sandbox' or 'production')
     */
    public static function getCashfreeEnvironment(): string {
        $mode = self::getMode();
        return ($mode === 'live') ? 'production' : 'sandbox';
    }

    /**
     * Create a Cashfree Payment Order (Cashfree PG API v2023-08-01)
     */
    public static function createCashfreeOrder(float $amount, string $orderId, array $customerDetails, string $orderNote = ''): array {
        $mode = self::getMode();
        $currency = (string)SystemSettings::get('payment_currency', 'INR');
        $env = self::getCashfreeEnvironment();

        $appId = self::getCashfreeAppId();
        $secretKey = self::getCashfreeSecretKey();

        // Sanitize / ensure valid customer info
        $customerId = preg_replace('/[^a-zA-Z0-9_-]/', '', (string)($customerDetails['customer_id'] ?? 'cust_' . time()));
        $customerPhone = preg_replace('/[^0-9]/', '', (string)($customerDetails['customer_phone'] ?? '9876543210'));
        if (strlen($customerPhone) < 10) $customerPhone = '9876543210';
        $customerEmail = filter_var($customerDetails['customer_email'] ?? '', FILTER_VALIDATE_EMAIL) ? $customerDetails['customer_email'] : 'candidate@examverse.com';
        $customerName = trim((string)($customerDetails['customer_name'] ?? 'ExamVerse Candidate'));

        // Mock / Sandbox fallback if live credentials not configured
        if ($mode === 'mock' || empty($appId) || empty($secretKey)) {
            $mockSessionId = 'session_cf_mock_' . bin2hex(random_bytes(16));
            $mockCfOrderId = 'cf_order_' . bin2hex(random_bytes(8));

            return [
                'success'            => true,
                'mode'               => 'mock',
                'gateway'            => 'cashfree',
                'environment'        => $env,
                'order_id'           => $orderId,
                'cf_order_id'        => $mockCfOrderId,
                'payment_session_id' => $mockSessionId,
                'order_amount'       => $amount,
                'order_currency'     => $currency,
                'customer_details'   => [
                    'customer_id'    => $customerId,
                    'customer_phone' => $customerPhone,
                    'customer_email' => $customerEmail,
                    'customer_name'  => $customerName,
                ],
                'order_status'       => 'ACTIVE',
            ];
        }

        $apiUrl = ($env === 'production')
            ? 'https://api.cashfree.com/pg/orders'
            : 'https://sandbox.cashfree.com/pg/orders';

        $postData = [
            'order_id'       => $orderId,
            'order_amount'   => round($amount, 2),
            'order_currency' => $currency,
            'customer_details' => [
                'customer_id'    => $customerId,
                'customer_phone' => $customerPhone,
                'customer_email' => $customerEmail,
                'customer_name'  => $customerName,
            ],
            'order_meta' => [
                'return_url' => AppConstants_apiBase() . "/v1/subscriptions/cashfree-return?order_id={$orderId}",
                'notify_url' => AppConstants_apiBase() . "/v1/subscriptions/cashfree-notify",
            ],
            'order_note' => !empty($orderNote) ? $orderNote : "ExamVerse Subscription Order {$orderId}",
        ];

        $ch = curl_init($apiUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'x-api-version: 2023-08-01',
            'x-client-id: ' . $appId,
            'x-client-secret: ' . $secretKey,
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 20);

        $res = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err) {
            return [
                'success' => false,
                'message' => 'Cashfree connection error: ' . $err,
            ];
        }

        $json = json_decode($res, true);
        if ($httpCode >= 200 && $httpCode < 300 && !empty($json['payment_session_id'])) {
            return [
                'success'            => true,
                'mode'               => $mode,
                'gateway'            => 'cashfree',
                'environment'        => $env,
                'order_id'           => $json['order_id'] ?? $orderId,
                'cf_order_id'        => $json['cf_order_id'] ?? '',
                'payment_session_id' => $json['payment_session_id'],
                'order_amount'       => $json['order_amount'] ?? $amount,
                'order_currency'     => $json['order_currency'] ?? $currency,
                'customer_details'   => $json['customer_details'] ?? [],
                'order_status'       => $json['order_status'] ?? 'ACTIVE',
                'raw'                => $json,
            ];
        }

        return [
            'success' => false,
            'message' => $json['message'] ?? 'Failed to initiate Cashfree order',
            'details' => $json,
        ];
    }

    /**
     * Verify Cashfree Order status
     */
    public static function verifyCashfreeOrder(string $orderId): array {
        $mode = self::getMode();
        $appId = self::getCashfreeAppId();
        $secretKey = self::getCashfreeSecretKey();

        if ($mode === 'mock' || empty($appId) || empty($secretKey)) {
            return [
                'success'      => true,
                'is_paid'      => true,
                'order_status' => 'PAID',
                'order_id'     => $orderId,
                'mode'         => 'mock',
            ];
        }

        $env = self::getCashfreeEnvironment();
        $apiUrl = ($env === 'production')
            ? "https://api.cashfree.com/pg/orders/{$orderId}"
            : "https://sandbox.cashfree.com/pg/orders/{$orderId}";

        $ch = curl_init($apiUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'x-api-version: 2023-08-01',
            'x-client-id: ' . $appId,
            'x-client-secret: ' . $secretKey,
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 20);

        $res = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err) {
            return [
                'success' => false,
                'is_paid' => false,
                'message' => 'Cashfree order check error: ' . $err,
            ];
        }

        $json = json_decode($res, true);
        $orderStatus = strtoupper((string)($json['order_status'] ?? ''));
        $isPaid = in_array($orderStatus, ['PAID', 'SUCCESS'], true);

        return [
            'success'      => ($httpCode >= 200 && $httpCode < 300),
            'is_paid'      => $isPaid,
            'order_status' => $orderStatus,
            'order_id'     => $json['order_id'] ?? $orderId,
            'order_amount' => $json['order_amount'] ?? 0,
            'raw'          => $json,
        ];
    }

    /**
     * Create an order for payment checkout (Razorpay backwards compatibility)
     */
    public static function createOrder(float $amount, string $receiptId, array $notes = []): array {
        $mode = self::getMode();
        $currency = (string)SystemSettings::get('payment_currency', 'INR');
        $amountInPaise = (int)round($amount * 100);

        if ($mode === 'mock' || !self::isEnabled()) {
            $mockOrderId = 'order_mock_' . bin2hex(random_bytes(8));
            return [
                'success' => true,
                'mode' => 'mock',
                'order_id' => $mockOrderId,
                'amount' => $amount,
                'amount_paise' => $amountInPaise,
                'currency' => $currency,
                'key_id' => 'mock_key_id'
            ];
        }

        $keyId = (string)SystemSettings::get('razorpay_key_id', '');
        $keySecret = (string)SystemSettings::get('razorpay_key_secret', '');

        if (empty($keyId) || empty($keySecret)) {
            return [
                'success' => false,
                'message' => 'Razorpay API credentials not configured in Admin Settings'
            ];
        }

        $url = 'https://api.razorpay.com/v1/orders';
        $postData = [
            'amount' => $amountInPaise,
            'currency' => $currency,
            'receipt' => (string)$receiptId,
            'notes' => $notes
        ];

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_USERPWD, "{$keyId}:{$keySecret}");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);

        $res = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err) {
            return [
                'success' => false,
                'message' => 'Razorpay gateway error: ' . $err
            ];
        }

        $json = json_decode($res, true);
        if ($httpCode >= 200 && $httpCode < 300 && !empty($json['id'])) {
            return [
                'success' => true,
                'mode' => $mode,
                'order_id' => $json['id'],
                'amount' => $amount,
                'amount_paise' => $json['amount'],
                'currency' => $json['currency'],
                'key_id' => $keyId,
                'raw' => $json
            ];
        }

        return [
            'success' => false,
            'message' => $json['error']['description'] ?? 'Failed to create payment order with Razorpay',
            'details' => $json
        ];
    }

    /**
     * Verify payment signature from Razorpay checkout response
     */
    public static function verifySignature(string $orderId, string $paymentId, string $signature): bool {
        $mode = self::getMode();
        if ($mode === 'mock') {
            return true;
        }

        $keySecret = (string)SystemSettings::get('razorpay_key_secret', '');
        if (empty($keySecret)) return false;

        $expectedSignature = hash_hmac('sha256', $orderId . '|' . $paymentId, $keySecret);
        return hash_equals($expectedSignature, $signature);
    }
}

function AppConstants_apiBase() {
    return 'https://staging.yatharthinstitution.in/api';
}
