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
     * Create an order for payment checkout
     * Amount is in currency units (e.g. INR 299.00)
     */
    public static function createOrder(float $amount, string $receiptId, array $notes = []): array {
        $mode = self::getMode();
        $currency = (string)SystemSettings::get('payment_currency', 'INR');
        $amountInPaise = (int)round($amount * 100);

        if ($mode === 'mock' || !self::isEnabled()) {
            // Mock Order creation
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
            return true; // Mock mode always succeeds
        }

        $keySecret = (string)SystemSettings::get('razorpay_key_secret', '');
        if (empty($keySecret)) return false;

        $expectedSignature = hash_hmac('sha256', $orderId . '|' . $paymentId, $keySecret);
        return hash_equals($expectedSignature, $signature);
    }
}
