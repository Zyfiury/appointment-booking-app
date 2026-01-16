# 💰 Commission System Documentation

## Overview

The platform takes a **15% commission** from each service booking. This commission is automatically calculated and tracked for every payment.

---

## How It Works

### Payment Flow

1. **Customer pays full service price**
   - Example: Customer pays $100 for a service

2. **Platform takes 15% commission**
   - Platform commission: $100 × 15% = **$15**
   - This is automatically deducted

3. **Provider receives 85%**
   - Provider amount: $100 - $15 = **$85**
   - Provider gets the remaining amount

---

## Database Schema

The `payments` table now includes:

- `amount` - Total amount paid by customer
- `platform_commission` - Platform's 15% commission
- `provider_amount` - Amount provider receives (85%)
- `commission_rate` - Commission rate (default: 15.00%)

### Example Record

```sql
amount: $100.00
platform_commission: $15.00
provider_amount: $85.00
commission_rate: 15.00%
```

---

## Backend Implementation

### Payment Creation

When a payment is created, the commission is automatically calculated:

```typescript
const COMMISSION_RATE = 15.00; // 15% commission
const platformCommission = (amount * COMMISSION_RATE) / 100;
const providerAmount = amount - platformCommission;
```

### Database Storage

All commission data is stored in the `payments` table:

- Commission is calculated on payment creation
- Stored permanently for record-keeping
- Can be queried for analytics/reporting

---

## Frontend Display

### Payment Screen

The payment screen now shows a commission breakdown:

- **Service Fee (15%)**: Shows platform commission
- **Provider Receives**: Shows amount provider gets

This provides transparency to customers about the fee structure.

---

## Commission Calculation Examples

| Service Price | Platform Commission (15%) | Provider Receives (85%) |
|--------------|---------------------------|------------------------|
| $50.00       | $7.50                     | $42.50                 |
| $100.00      | $15.00                    | $85.00                 |
| $200.00      | $30.00                    | $170.00                |
| $500.00      | $75.00                    | $425.00                |

---

## Changing Commission Rate

To change the commission rate:

1. **Backend**: Update `COMMISSION_RATE` in `server/routes/payments.ts`
2. **Database**: The `commission_rate` field stores the rate used for each payment
3. **Note**: Changing the rate only affects new payments, not existing ones

### Example: Change to 20%

```typescript
// In server/routes/payments.ts
const COMMISSION_RATE = 20.00; // Changed from 15% to 20%
```

---

## Querying Commission Data

### Get Total Platform Revenue

```sql
SELECT SUM(platform_commission) as total_revenue
FROM payments
WHERE status = 'completed';
```

### Get Provider Earnings

```sql
SELECT SUM(provider_amount) as total_earnings
FROM payments
WHERE status = 'completed'
AND appointment_id IN (
  SELECT id FROM appointments WHERE provider_id = 'provider_id_here'
);
```

### Get Commission by Date Range

```sql
SELECT 
  DATE(created_at) as date,
  SUM(platform_commission) as daily_commission,
  COUNT(*) as payment_count
FROM payments
WHERE status = 'completed'
  AND created_at >= '2024-01-01'
  AND created_at <= '2024-12-31'
GROUP BY DATE(created_at)
ORDER BY date;
```

---

## Refunds

When a payment is refunded:

- The commission is also refunded
- Both customer and provider amounts are reversed
- Status changes to 'refunded'

---

## Future Enhancements

Potential improvements:

1. **Provider Dashboard**: Show earnings and commission breakdown
2. **Admin Dashboard**: View total platform revenue
3. **Commission Reports**: Generate monthly/yearly reports
4. **Variable Commission**: Different rates for different providers/services
5. **Commission History**: Track commission rate changes over time

---

## API Response Example

```json
{
  "id": "1234567890",
  "appointmentId": "appt_123",
  "amount": 100.00,
  "currency": "USD",
  "status": "completed",
  "paymentMethod": "card",
  "platformCommission": 15.00,
  "providerAmount": 85.00,
  "commissionRate": 15.00,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

---

## Testing

To test the commission system:

1. **Create a payment** with amount $100
2. **Verify**:
   - `platformCommission` = $15.00
   - `providerAmount` = $85.00
   - `commissionRate` = 15.00

3. **Check database**:
   ```sql
   SELECT * FROM payments WHERE id = 'payment_id';
   ```

---

## Summary

✅ **15% commission automatically calculated**  
✅ **Stored in database for record-keeping**  
✅ **Transparent display in payment screen**  
✅ **Easy to query for analytics**  
✅ **Supports refunds**  

The commission system is now fully integrated and working! 🎉
