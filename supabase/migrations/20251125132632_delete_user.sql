CREATE OR REPLACE FUNCTION public.handle_deleted_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- 使用管理者權限，確保能刪除跨 schema 的資料
AS $$
BEGIN
  -- OLD.id 就是被刪除的 auth.users 的 id  
  -- 刪除 internal.accounts
  DELETE FROM internal.accounts WHERE user_id = OLD.id;
  
  -- 刪除 public.records
  DELETE FROM public.records WHERE user_id = OLD.id;
  
  -- 刪除 public.pets
  DELETE FROM public.pets WHERE user_id = OLD.id;
  
  -- 刪除 public.storage_items
  -- (假設 owner_type 是 'user' 時 owner_id 對應 user_id)
  DELETE FROM public.storage_items 
  WHERE owner_id = OLD.id AND owner_type = 'User'; -- 加上 owner_type 檢查更安全

  -- 刪除 public.users 本身
  DELETE FROM public.users WHERE id = OLD.id;

  RETURN OLD;
END;
$$;

-- 在 auth.users 表上建立 Trigger
CREATE TRIGGER on_auth_user_deleted
  AFTER DELETE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_deleted_user();