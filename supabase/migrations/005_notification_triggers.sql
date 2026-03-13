-- Notification triggers for push notifications
-- These triggers call the send-notification edge function when relevant events occur

-- Function to get partner ID from a couple
CREATE OR REPLACE FUNCTION get_partner_id(p_couple_id UUID, p_sender_id UUID)
RETURNS UUID AS $$
DECLARE
  v_partner_id UUID;
BEGIN
  SELECT CASE
    WHEN partner_1 = p_sender_id THEN partner_2
    ELSE partner_1
  END INTO v_partner_id
  FROM couples
  WHERE id = p_couple_id;
  
  RETURN v_partner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send notification via edge function
CREATE OR REPLACE FUNCTION notify_partner()
RETURNS TRIGGER AS $$
DECLARE
  v_partner_id UUID;
  v_sender_name TEXT;
  v_notification_type TEXT;
  v_day_number INT;
BEGIN
  -- Get partner ID
  v_partner_id := get_partner_id(NEW.couple_id, NEW.sender_id);
  
  IF v_partner_id IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Get sender name
  SELECT display_name INTO v_sender_name
  FROM profiles
  WHERE id = NEW.sender_id;
  
  -- Determine notification type based on table
  IF TG_TABLE_NAME = 'taps' THEN
    v_notification_type := 'tap';
  ELSIF TG_TABLE_NAME = 'photos' THEN
    v_notification_type := 'photo';
  ELSIF TG_TABLE_NAME = 'love_notes' THEN
    v_notification_type := 'note';
  END IF;
  
  -- Call edge function (fire and forget via pg_net)
  PERFORM net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object(
      'type', v_notification_type,
      'sender_id', NEW.sender_id,
      'recipient_id', v_partner_id,
      'sender_name', v_sender_name
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify about daily questions
CREATE OR REPLACE FUNCTION notify_daily_question()
RETURNS TRIGGER AS $$
DECLARE
  v_partner_1 UUID;
  v_partner_2 UUID;
BEGIN
  -- Only notify when question is unlocked
  IF NEW.unlocked_at IS NOT NULL AND OLD.unlocked_at IS NULL THEN
    SELECT partner_1, partner_2 INTO v_partner_1, v_partner_2
    FROM couples
    WHERE id = NEW.couple_id;
    
    -- Notify both partners
    PERFORM net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'type', 'question',
        'sender_id', v_partner_1,
        'recipient_id', v_partner_2,
        'day_number', NEW.day_number
      )
    );
    
    IF v_partner_1 IS NOT NULL THEN
      PERFORM net.http_post(
        url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
        ),
        body := jsonb_build_object(
          'type', 'question',
          'sender_id', v_partner_2,
          'recipient_id', v_partner_1,
          'day_number', NEW.day_number
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
DROP TRIGGER IF EXISTS on_tap_created ON taps;
CREATE TRIGGER on_tap_created
  AFTER INSERT ON taps
  FOR EACH ROW
  EXECUTE FUNCTION notify_partner();

DROP TRIGGER IF EXISTS on_photo_created ON photos;
CREATE TRIGGER on_photo_created
  AFTER INSERT ON photos
  FOR EACH ROW
  EXECUTE FUNCTION notify_partner();

DROP TRIGGER IF EXISTS on_note_created ON love_notes;
CREATE TRIGGER on_note_created
  AFTER INSERT ON love_notes
  FOR EACH ROW
  WHEN (NEW.category = 'instant' AND NEW.delivered = true)
  EXECUTE FUNCTION notify_partner();

DROP TRIGGER IF EXISTS on_question_unlocked ON daily_questions;
CREATE TRIGGER on_question_unlocked
  AFTER UPDATE ON daily_questions
  FOR EACH ROW
  EXECUTE FUNCTION notify_daily_question();
