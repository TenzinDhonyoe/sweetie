-- Fix notification triggers to not break core operations when pg_net is unavailable
-- Uses dynamic SQL so function creation succeeds even without the net schema

CREATE OR REPLACE FUNCTION notify_partner_joined()
RETURNS TRIGGER AS $$
DECLARE
  v_joiner_name TEXT;
BEGIN
  IF OLD.partner_2 IS NULL AND NEW.partner_2 IS NOT NULL THEN
    -- Only attempt notification if pg_net extension is available
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
      SELECT display_name INTO v_joiner_name
      FROM profiles
      WHERE id = NEW.partner_2;

      BEGIN
        EXECUTE format(
          'SELECT net.http_post(url := %L, headers := %L::jsonb, body := %L::jsonb)',
          current_setting('app.settings.supabase_url', true) || '/functions/v1/send-notification',
          jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
          )::text,
          jsonb_build_object(
            'type', 'partner_joined',
            'sender_id', NEW.partner_2,
            'recipient_id', NEW.partner_1,
            'sender_name', v_joiner_name
          )::text
        );
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'notify_partner_joined failed: %', SQLERRM;
      END;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_partner()
RETURNS TRIGGER AS $$
DECLARE
  v_partner_id UUID;
  v_sender_name TEXT;
  v_notification_type TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RETURN NEW;
  END IF;

  v_partner_id := get_partner_id(NEW.couple_id, NEW.sender_id);

  IF v_partner_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_sender_name
  FROM profiles
  WHERE id = NEW.sender_id;

  IF TG_TABLE_NAME = 'taps' THEN
    v_notification_type := 'tap';
  ELSIF TG_TABLE_NAME = 'photos' THEN
    v_notification_type := 'photo';
  ELSIF TG_TABLE_NAME = 'love_notes' THEN
    v_notification_type := 'note';
  END IF;

  BEGIN
    EXECUTE format(
      'SELECT net.http_post(url := %L, headers := %L::jsonb, body := %L::jsonb)',
      current_setting('app.settings.supabase_url', true) || '/functions/v1/send-notification',
      jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      )::text,
      jsonb_build_object(
        'type', v_notification_type,
        'sender_id', NEW.sender_id,
        'recipient_id', v_partner_id,
        'sender_name', v_sender_name
      )::text
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_partner failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_daily_question()
RETURNS TRIGGER AS $$
DECLARE
  v_partner_1 UUID;
  v_partner_2 UUID;
BEGIN
  IF NEW.unlocked_at IS NOT NULL AND OLD.unlocked_at IS NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
      RETURN NEW;
    END IF;

    SELECT partner_1, partner_2 INTO v_partner_1, v_partner_2
    FROM couples
    WHERE id = NEW.couple_id;

    BEGIN
      EXECUTE format(
        'SELECT net.http_post(url := %L, headers := %L::jsonb, body := %L::jsonb)',
        current_setting('app.settings.supabase_url', true) || '/functions/v1/send-notification',
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
        )::text,
        jsonb_build_object(
          'type', 'question',
          'sender_id', v_partner_1,
          'recipient_id', v_partner_2,
          'day_number', NEW.day_number
        )::text
      );

      IF v_partner_1 IS NOT NULL THEN
        EXECUTE format(
          'SELECT net.http_post(url := %L, headers := %L::jsonb, body := %L::jsonb)',
          current_setting('app.settings.supabase_url', true) || '/functions/v1/send-notification',
          jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
          )::text,
          jsonb_build_object(
            'type', 'question',
            'sender_id', v_partner_2,
            'recipient_id', v_partner_1,
            'day_number', NEW.day_number
          )::text
        );
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_daily_question failed: %', SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
