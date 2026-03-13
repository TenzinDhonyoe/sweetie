-- ============================================================
-- Daily Questions — Realtime, Constraint & Seed Trigger
-- ============================================================

-- Enable realtime for daily_questions
alter publication supabase_realtime add table daily_questions;

-- Prevent duplicate seeds
alter table daily_questions add constraint unique_couple_day unique (couple_id, day_number);

-- Seed 10 questions when partner_2 joins
create or replace function seed_daily_questions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only fire when partner_2 transitions from NULL to a value
  if old.partner_2 is not null or new.partner_2 is null then
    return new;
  end if;

  insert into daily_questions (couple_id, question_text, day_number) values
    (new.id, 'What''s one thing about us that you''d never change?', 1),
    (new.id, 'What''s a small moment together that you think about more than I''d expect?', 2),
    (new.id, 'If we could teleport anywhere right now for one hour, where would we go?', 3),
    (new.id, 'What''s something you''ve been wanting to tell me but keep forgetting to?', 4),
    (new.id, 'Describe your perfect lazy Sunday with me in 3 sentences.', 5),
    (new.id, 'What song makes you think of me every time you hear it?', 6),
    (new.id, 'What''s one new thing you want us to try together when I''m back?', 7),
    (new.id, 'If you could relive one day we''ve had together, which would it be?', 8),
    (new.id, 'What''s something I do that makes you feel most loved?', 9),
    (new.id, 'Write me a tiny love letter in exactly 3 lines.', 10)
  on conflict (couple_id, day_number) do nothing;

  return new;
end;
$$;

create trigger on_couple_paired
  after update on couples
  for each row execute function seed_daily_questions();
