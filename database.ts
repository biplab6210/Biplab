// Hand-authored types matching supabase/schema.sql.
// Once your Supabase project is live, regenerate the authoritative
// version with:
//   npx supabase gen types typescript --project-id YOUR_REF > types/database.ts
// Keep this file as a fallback / reference for local type-checking
// until you do.

export type ServiceStatus = 'published' | 'draft' | 'hidden';
export type OrderStatus = 'new' | 'pending' | 'in_progress' | 'completed' | 'cancelled';
export type CouponDiscountType = 'percentage' | 'fixed';
export type PortfolioCategory =
  | 'websites' | 'advertisements' | 'videos' | 'graphics' | 'ai_projects' | 'other';
export type PaymentStatus = 'submitted' | 'verified' | 'rejected';
export type MessageStatus = 'unread' | 'read' | 'archived';

export interface Service {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  image_url: string | null;
  icon: string | null;
  category: string | null;
  starting_price: number;
  discount_percent: number;
  features: string[];
  status: ServiceStatus;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface PricingPackage {
  id: string;
  service_id: string | null;
  package_name: string;
  description: string | null;
  features: string[];
  original_price: number;
  discount_percent: number;
  final_price: number; // generated column
  status: ServiceStatus;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface Coupon {
  id: string;
  code: string;
  discount_type: CouponDiscountType;
  discount_value: number;
  min_order_amount: number;
  max_discount_amount: number | null;
  usage_limit: number | null;
  usage_count: number;
  start_date: string | null;
  expiry_date: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PortfolioItem {
  id: string;
  title: string;
  description: string | null;
  image_url: string | null;
  video_url: string | null;
  project_url: string | null;
  category: PortfolioCategory;
  project_date: string | null;
  status: ServiceStatus;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface Order {
  id: string;
  order_number: string;
  customer_id: string | null;
  customer_name: string;
  phone: string;
  whatsapp: string | null;
  email: string | null;
  service_id: string | null;
  service_name_snapshot: string | null;
  package_id: string | null;
  package_name_snapshot: string | null;
  coupon_id: string | null;
  coupon_code_snapshot: string | null;
  original_price: number;
  discount_amount: number;
  final_price: number;
  message: string | null;
  status: OrderStatus;
  created_at: string;
  updated_at: string;
}

export interface Payment {
  id: string;
  order_id: string;
  amount: number;
  utr_number: string | null;
  screenshot_url: string | null;
  status: PaymentStatus;
  admin_note: string | null;
  created_at: string;
  updated_at: string;
}

export interface Message {
  id: string;
  name: string;
  phone: string | null;
  email: string | null;
  message: string;
  status: MessageStatus;
  created_at: string;
}

export interface SocialLink {
  id: string;
  platform: string;
  url: string;
  is_active: boolean;
  sort_order: number;
}

export interface WebsiteSetting {
  key: string;
  value: unknown;
  updated_at: string;
}

export interface Media {
  id: string;
  file_name: string;
  storage_path: string;
  public_url: string;
  mime_type: string;
  size_bytes: number;
  purpose: string | null;
  uploaded_by: string | null;
  created_at: string;
}

export interface AdminUser {
  id: string;
  full_name: string;
  role: 'admin' | 'superadmin';
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

// Minimal Supabase `Database` generic shape used by createClient<Database>().
// This keeps type inference working without the full generated file.
export interface Database {
  public: {
    Tables: {
      services: { Row: Service; Insert: Partial<Service>; Update: Partial<Service> };
      pricing_packages: { Row: PricingPackage; Insert: Partial<PricingPackage>; Update: Partial<PricingPackage> };
      coupons: { Row: Coupon; Insert: Partial<Coupon>; Update: Partial<Coupon> };
      portfolio: { Row: PortfolioItem; Insert: Partial<PortfolioItem>; Update: Partial<PortfolioItem> };
      orders: { Row: Order; Insert: Partial<Order>; Update: Partial<Order> };
      payments: { Row: Payment; Insert: Partial<Payment>; Update: Partial<Payment> };
      messages: { Row: Message; Insert: Partial<Message>; Update: Partial<Message> };
      social_links: { Row: SocialLink; Insert: Partial<SocialLink>; Update: Partial<SocialLink> };
      website_settings: { Row: WebsiteSetting; Insert: Partial<WebsiteSetting>; Update: Partial<WebsiteSetting> };
      media: { Row: Media; Insert: Partial<Media>; Update: Partial<Media> };
      admin_users: { Row: AdminUser; Insert: Partial<AdminUser>; Update: Partial<AdminUser> };
    };
  };
}
