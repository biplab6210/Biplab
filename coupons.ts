import 'server-only';
import { createAdminSupabaseClient } from '@/lib/supabase/admin';
import type { Coupon } from '@/types/database';

export interface CouponValidationResult {
  valid: boolean;
  reason?: string;
  coupon?: Coupon;
  discountAmount?: number;
  finalPrice?: number;
}

/**
 * Validates a coupon code against an order amount and computes the
 * discount SERVER-SIDE. This is the only place coupon math should
 * happen — never trust a discount/final price sent from the browser.
 * Callers (app/api/orders route, app/api/coupons/validate route) must
 * always recompute with this function before persisting an order.
 */
export async function validateAndApplyCoupon(
  code: string,
  orderAmount: number
): Promise<CouponValidationResult> {
  if (!code || !code.trim()) {
    return { valid: false, reason: 'No coupon code provided.' };
  }

  const supabase = createAdminSupabaseClient();
  const { data: coupon, error } = await supabase
    .from('coupons')
    .select('*')
    .ilike('code', code.trim())
    .maybeSingle();

  if (error || !coupon) {
    return { valid: false, reason: 'Invalid or expired coupon code.' };
  }

  const c = coupon as Coupon;
  const now = new Date();

  if (!c.is_active) {
    return { valid: false, reason: 'Invalid or expired coupon code.' };
  }
  if (c.start_date && new Date(c.start_date) > now) {
    return { valid: false, reason: 'Invalid or expired coupon code.' };
  }
  if (c.expiry_date && new Date(c.expiry_date) < now) {
    return { valid: false, reason: 'Invalid or expired coupon code.' };
  }
  if (c.usage_limit !== null && c.usage_count >= c.usage_limit) {
    return { valid: false, reason: 'Invalid or expired coupon code.' };
  }
  if (orderAmount < c.min_order_amount) {
    return {
      valid: false,
      reason: `This coupon requires a minimum order of ₹${c.min_order_amount}.`,
    };
  }

  let discountAmount =
    c.discount_type === 'percentage'
      ? (orderAmount * c.discount_value) / 100
      : c.discount_value;

  if (c.max_discount_amount !== null) {
    discountAmount = Math.min(discountAmount, c.max_discount_amount);
  }
  // Never let a discount exceed the order amount itself.
  discountAmount = Math.min(discountAmount, orderAmount);
  discountAmount = Math.round(discountAmount * 100) / 100;

  const finalPrice = Math.round((orderAmount - discountAmount) * 100) / 100;

  return { valid: true, coupon: c, discountAmount, finalPrice };
}

/**
 * Atomically increments a coupon's usage_count via the
 * `increment_coupon_usage` Postgres function (see supabase/schema.sql).
 * Call this only after an order has actually been persisted
 * successfully, so failed orders don't burn a use of a limited coupon.
 * Uses a DB-side atomic increment rather than read-then-write to avoid
 * a race condition under concurrent orders.
 */
export async function incrementCouponUsage(couponId: string) {
  const supabase = createAdminSupabaseClient();
  const { error } = await supabase.rpc('increment_coupon_usage', {
    coupon_id: couponId,
  });
  if (error) {
    // Non-fatal: the order itself already succeeded. Log for admin visibility.
    console.error('Failed to increment coupon usage_count:', error.message);
  }
}
