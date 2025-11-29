CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile public.users;
  v_meta jsonb;
  v_username text;
  v_phone text;
  v_gender e.gender;
BEGIN
  -- 1. 從 auth.users 獲取 Metadata
  SELECT raw_user_meta_data INTO v_meta 
  FROM auth.users 
  WHERE id = auth.uid();

  -- 2. 解析資料
  v_username := COALESCE(v_meta->>'user_name', v_meta->>'full_name', v_meta->>'name', 'User');
  v_phone := v_meta->>'phone';
  v_gender := v_meta->>'gender';

  -- 3. 寫入 public.users
  INSERT INTO public.users(
      id,
      email,
      username,
      gender,
      phone,
      relationship,
      dob
  )
  VALUES (
      auth.uid(), 
      auth.email(),
      v_username,
      v_gender,
      v_phone,
      NULL, 
      NULL   
  )
  ON CONFLICT (id)
  DO UPDATE SET 
      email = EXCLUDED.email -- [!!] 注意：這裡不要分號
  
  RETURNING * INTO v_profile; -- [!!] 分號要加在這裡
  
  RETURN v_profile;
END;
$$;