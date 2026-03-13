-- ============================================================
-- Sweetie — Storage Bucket for User Avatars
-- ============================================================

-- Create the avatars storage bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152, -- 2MB
  array['image/jpeg', 'image/png']
);

-- RLS: Users can upload/update their own avatar
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.filename(name)) = auth.uid()::text || '.jpg'
  );

create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.filename(name)) = auth.uid()::text || '.jpg'
  );

-- RLS: Public read access for avatars
create policy "Public can read avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');
