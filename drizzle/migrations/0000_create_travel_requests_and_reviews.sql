CREATE TABLE public.trip_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 reference uuid NOT NULL UNIQUE,
 trip_type text NOT NULL CHECK (trip_type IN ('one-way','round-trip','local')),
 pickup text NOT NULL CHECK (length(pickup) BETWEEN 2 AND 160),
 destination text NOT NULL CHECK (length(destination) BETWEEN 2 AND 160),
 travel_date date NOT NULL,
 return_date date,
 vehicle text NOT NULL CHECK (vehicle IN ('sedan','innova','traveller')),
 customer_name text NOT NULL CHECK (length(customer_name) BETWEEN 2 AND 100),
 phone text NOT NULL CHECK (phone ~ '^[+]?[0-9 ()-]{10,20}$'),
 language text NOT NULL DEFAULT 'en' CHECK (language IN ('en','te','hi','ta')),
 status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','cancelled')),
 created_at timestamptz NOT NULL DEFAULT now()
);
GRANT INSERT ON public.trip_requests TO anon, authenticated;
GRANT ALL ON public.trip_requests TO service_role;
ALTER TABLE public.trip_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Visitors submit pending trip requests" ON public.trip_requests FOR INSERT TO anon, authenticated WITH CHECK (status = 'pending');
CREATE FUNCTION public.validate_trip_dates() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$ BEGIN IF NEW.travel_date < (now() AT TIME ZONE 'Asia/Kolkata')::date THEN RAISE EXCEPTION 'Travel date must not be in the past'; END IF; IF NEW.trip_type = 'round-trip' AND (NEW.return_date IS NULL OR NEW.return_date < NEW.travel_date) THEN RAISE EXCEPTION 'Valid return date required'; END IF; RETURN NEW; END; $$;
CREATE TRIGGER validate_trip_request_dates BEFORE INSERT OR UPDATE ON public.trip_requests FOR EACH ROW EXECUTE FUNCTION public.validate_trip_dates();
CREATE TABLE public.customer_reviews (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 name text NOT NULL CHECK (length(name) BETWEEN 2 AND 100),
 rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
 message text NOT NULL CHECK (length(message) BETWEEN 10 AND 600),
 approved boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.customer_reviews TO anon, authenticated;
GRANT ALL ON public.customer_reviews TO service_role;
ALTER TABLE public.customer_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads approved reviews" ON public.customer_reviews FOR SELECT TO anon, authenticated USING (approved = true);
CREATE POLICY "Visitors submit reviews for approval" ON public.customer_reviews FOR INSERT TO anon, authenticated WITH CHECK (approved = false);