-- Notify partner_1 when someone joins their couple using the invite code

CREATE OR REPLACE FUNCTION notify_partner_joined()
RETURNS TRIGGER AS $$
DECLARE
  v_joiner_name TEXT;
BEGIN
  -- Only fire when partner_2 transitions from NULL to a value
  IF OLD.partner_2 IS NULL AND NEW.partner_2 IS NOT NULL THEN
    -- Get the joining partner's display name
    SELECT display_name INTO v_joiner_name
    FROM profiles
    WHERE id = NEW.partner_2;

    -- Notify partner_1 (the one who created the couple)
    PERFORM net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'type', 'partner_joined',
        'sender_id', NEW.partner_2,
        'recipient_id', NEW.partner_1,
        'sender_name', v_joiner_name
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_partner_joined ON couples;
CREATE TRIGGER on_partner_joined
  AFTER UPDATE ON couples
  FOR EACH ROW
  EXECUTE FUNCTION notify_partner_joined();
