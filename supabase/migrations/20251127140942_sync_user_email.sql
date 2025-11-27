-- 1. 建立一個函式，負責執行 "同步更新" 的動作
CREATE OR REPLACE FUNCTION public.sync_user_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- 使用系統權限執行，確保能修改 public.users
AS $$
BEGIN
  -- 當 auth.users 的 email 更新時，同步更新 public.users
  UPDATE public.users
  SET email = NEW.email
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$;

-- 2. 建立 Trigger，監聽 auth.users 的 UPDATE 事件
CREATE TRIGGER on_auth_user_email_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  -- 只有當 email 真的有變動時才執行 (節省效能)
  WHEN (OLD.email IS DISTINCT FROM NEW.email)
  EXECUTE FUNCTION public.sync_user_email();