-- ============================================================
-- Close To You — Storage Bucket for Couple Photos
-- ============================================================

-- Create the couple-photos storage bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'couple-photos',
  'couple-photos',
  true,
  5242880, -- 5MB
  array['image/jpeg', 'image/png']
);

-- RLS: Users can upload to their couple's folder
create policy "Couples can upload photos"
  on storage.objects for insert
  with check (
    bucket_id = 'couple-photos'
    and (storage.foldername(name))[1] = get_couple_id(auth.uid())::text
  );

-- RLS: Users can read their couple's photos
create policy "Couples can read photos"
  on storage.objects for select
  using (
    bucket_id = 'couple-photos'
    and (storage.foldername(name))[1] = get_couple_id(auth.uid())::text
  );

-- RLS: Public read access for couple-photos (since bucket is public)
create policy "Public can read couple photos"
  on storage.objects for select
  using (bucket_id = 'couple-photos');
